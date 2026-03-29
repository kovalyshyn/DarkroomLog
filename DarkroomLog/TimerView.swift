import SwiftUI
import AVFoundation
import CoreMotion

struct TimerView: View {
    var onStop: ((Int) -> Void)? = nil

    @State private var elapsed: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var audioPlayer: AVAudioPlayer?
    @State private var motionManager = CMMotionManager()
    @State private var lastGestureTime: Date = .distantPast
    @State private var inFreefall = false
    @State private var freefallStart: Date = .distantPast
    @State private var originalBrightness: CGFloat = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }.first?.screen.brightness ?? 0.5

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(formattedTime)
                    .font(.system(size: 100, weight: .thin, design: .monospaced))
                    .foregroundStyle(isRunning ? Color(red: 1, green: 0.08, blue: 0) : Color(red: 0.4, green: 0, blue: 0))
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: elapsed)

                Spacer()

                Text(isRunning ? "tap · knock · toss to restart" : "tap to start")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(red: 0.3, green: 0.05, blue: 0.05))
                    .padding(.bottom, 48)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .gesture(
            DragGesture(minimumDistance: 60)
                .onEnded { value in
                    if value.translation.width > 80 {
                        stopTimer()
                        dismiss()
                    }
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Timer")
                    .foregroundStyle(Color(red: 0.4, green: 0.1, blue: 0.1))
                    .font(.subheadline)
            }
            if onStop != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use this time") {
                        onStop?(elapsed)
                    }
                    .foregroundStyle(Color(red: 0.7, green: 0.2, blue: 0.2))
                    .disabled(!isRunning && elapsed == 0)
                }
            }
        }
        .onAppear {
            setupAudio()
            startMotionDetection()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            stopTimer()
            motionManager.stopAccelerometerUpdates()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(isRunning)
        .toolbar(isRunning ? .hidden : .visible, for: .navigationBar)
    }

    private var formattedTime: String {
        let m = elapsed / 60
        let s = elapsed % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Tap

    private func handleTap() {
        if isRunning {
            restartTimer()
        } else {
            startTimer()
        }
    }

    // MARK: - Timer control

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen
    }

    private func startTimer() {
        originalBrightness = screen?.brightness ?? 0.5
        screen?.brightness = 0.02
        isRunning = true
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed += 1
            playTick()
        }
    }

    private func restartTimer() {
        guard isRunning else { return }
        timer?.invalidate()
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed += 1
            playTick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        screen?.brightness = originalBrightness
    }

    // MARK: - Audio

    private func setupAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: "tick", withExtension: "wav") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
    }

    private func playTick() {
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }

    // MARK: - Motion detection

    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05 // 20 Hz

        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            let magnitude = sqrt(
                data.acceleration.x * data.acceleration.x +
                data.acceleration.y * data.acceleration.y +
                data.acceleration.z * data.acceleration.z
            )

            if magnitude < 0.35 {
                if !inFreefall {
                    inFreefall = true
                    freefallStart = Date()
                }
            } else {
                if inFreefall {
                    inFreefall = false
                    let duration = Date().timeIntervalSince(freefallStart)
                    if duration > 0.08 && magnitude > 1.5 {
                        triggerRestart()
                    }
                }
            }

            if magnitude > 2.2 {
                triggerRestart()
            }
        }
    }

    private func triggerRestart() {
        guard isRunning else { return }
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) > 0.5 else { return }
        lastGestureTime = now
        DispatchQueue.main.async { restartTimer() }
    }
}
