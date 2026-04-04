import SwiftUI
import AVFoundation
import CoreMotion

struct TimerView: View {
    var onStop: ((Int) -> Void)? = nil
    var intervals: [Int] = []
    var darkroomMode: Bool = true

    @State private var elapsed: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var audioPlayer: AVAudioPlayer?
    @State private var bellPlayer: AVAudioPlayer?
    @State private var motionManager = CMMotionManager()
    @State private var lastGestureTime: Date = .distantPast
    @State private var inFreefall = false
    @State private var freefallStart: Date = .distantPast
    @State private var originalBrightness: CGFloat = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }.first?.screen.brightness ?? 0.5
    @State private var nextTargetIndex: Int = 0

    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    private var cumulativeTargets: [Int] {
        var result: [Int] = []
        var sum = 0
        for d in intervals {
            sum += d
            result.append(sum)
        }
        return result
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if !intervals.isEmpty && isRunning {
                    Text("Step \(min(nextTargetIndex + 1, intervals.count)) of \(intervals.count)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(darkroomMode ? Color(red: 0.4, green: 0, blue: 0) : Color.white.opacity(0.5))
                        .padding(.bottom, 8)
                }

                Text(formattedTime)
                    .font(.system(size: 100, weight: .thin, design: .monospaced))
                    .foregroundStyle(darkroomMode
                        ? (isRunning ? Color(red: 1, green: 0.08, blue: 0) : Color(red: 0.4, green: 0, blue: 0))
                        : (isRunning ? Color.white : Color.white.opacity(0.35)))
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: elapsed)

                Spacer()

                Text(isRunning ? "tap · knock · toss to restart" : "tap to start")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(darkroomMode ? Color(red: 0.3, green: 0.05, blue: 0.05) : Color.white.opacity(0.3))
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Timer")
                    .foregroundStyle(darkroomMode ? Color(red: 0.4, green: 0.1, blue: 0.1) : Color.white.opacity(0.6))
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
        if darkroomMode { screen?.brightness = 0.02 }
        isRunning = true
        elapsed = 0
        nextTargetIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed += 1
            playTick()
            checkIntervalBell()
            checkMinuteBell()
        }
    }

    private func restartTimer() {
        guard isRunning else { return }
        timer?.invalidate()
        elapsed = 0
        nextTargetIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed += 1
            playTick()
            checkIntervalBell()
            checkMinuteBell()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        screen?.brightness = originalBrightness
    }

    // MARK: - Interval bells

    private func checkIntervalBell() {
        let targets = cumulativeTargets
        guard nextTargetIndex < targets.count else { return }
        if elapsed == targets[nextTargetIndex] {
            playBell()
            nextTargetIndex += 1
            if nextTargetIndex >= targets.count {
                stopTimer()
            }
        }
    }

    // MARK: - Minute bell (film development timer only)

    private func checkMinuteBell() {
        guard !darkroomMode, elapsed > 0, elapsed % 60 == 0 else { return }
        playBell()
    }

    // MARK: - Audio

    private func setupAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: "tick", withExtension: "wav") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
        if let url = Bundle.main.url(forResource: "bell", withExtension: "wav") {
            bellPlayer = try? AVAudioPlayer(contentsOf: url)
            bellPlayer?.prepareToPlay()
        }
    }

    private func playTick() {
        guard metronomeEnabled else { return }
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }

    private func playBell() {
        bellPlayer?.currentTime = 0
        bellPlayer?.play()
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
