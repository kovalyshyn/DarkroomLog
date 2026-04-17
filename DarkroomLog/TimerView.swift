import SwiftUI
import AVFoundation
import CoreMotion

struct TimerView: View {
    var onStop: ((Int) -> Void)? = nil
    var intervals: [Int] = []
    var stepNames: [String] = []
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
    @State private var skipIntervals: Bool = false

    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    private var stepProgress: Double {
        guard !intervals.isEmpty, isRunning, !skipIntervals,
              nextTargetIndex < intervals.count else { return 0 }
        let stepStart = nextTargetIndex > 0 ? cumulativeTargets[nextTargetIndex - 1] : 0
        let stepDuration = intervals[nextTargetIndex]
        guard stepDuration > 0 else { return 1 }
        return Double(elapsed - stepStart) / Double(stepDuration)
    }

    private var currentStepName: String? {
        guard stepNames.count == intervals.count,
              nextTargetIndex < stepNames.count else { return nil }
        let n = stepNames[nextTargetIndex]
        return n.isEmpty ? nil : n
    }

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

                if !intervals.isEmpty && isRunning && !skipIntervals {
                    VStack(spacing: 4) {
                        if let name = currentStepName {
                            Text(name)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(darkroomMode ? Color(red: 0.5, green: 0.05, blue: 0.05) : Color.white.opacity(0.55))
                        }
                        Text("\(min(nextTargetIndex + 1, intervals.count)) / \(intervals.count)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(darkroomMode ? Color(red: 0.4, green: 0, blue: 0) : Color.white.opacity(0.4))
                    }
                    .padding(.bottom, 10)
                }

                Text(formattedTime)
                    .font(.system(size: 100, weight: .thin, design: .monospaced))
                    .foregroundStyle(darkroomMode
                        ? (isRunning ? Color(red: 1, green: 0.08, blue: 0) : Color(red: 0.4, green: 0, blue: 0))
                        : (isRunning ? Color.white : Color.white.opacity(0.35)))
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: elapsed)

                if !intervals.isEmpty && isRunning && !skipIntervals {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(darkroomMode ? Color(red: 0.2, green: 0, blue: 0) : Color.white.opacity(0.12))
                                .frame(height: 2)
                            Rectangle()
                                .fill(darkroomMode ? Color(red: 0.85, green: 0.1, blue: 0) : Color.white.opacity(0.65))
                                .frame(width: geo.size.width * max(0, min(1, stepProgress)), height: 2)
                                .animation(.linear(duration: 1), value: elapsed)
                        }
                    }
                    .frame(height: 2)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }

                Spacer()

                if let onStop {
                    Button("Use this time") { onStop(elapsed) }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(isRunning || elapsed > 0
                            ? Color(red: 0.7, green: 0.2, blue: 0.2)
                            : Color(red: 0.3, green: 0.05, blue: 0.05))
                        .disabled(!isRunning && elapsed == 0)
                        .padding(.bottom, 16)
                }

                let hintText: String = {
                    if isRunning { return "tap · knock · toss to restart" }
                    if skipIntervals && !intervals.isEmpty { return "tap to continue free" }
                    return "tap to start"
                }()
                Text(hintText)
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
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea(edges: .top)
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
        .statusBarHidden(true)
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
        skipIntervals = false
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
        guard !skipIntervals else { return }
        let targets = cumulativeTargets
        guard nextTargetIndex < targets.count else { return }
        if elapsed == targets[nextTargetIndex] {
            playBell()
            nextTargetIndex += 1
            if nextTargetIndex >= targets.count {
                skipIntervals = true
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
                    if duration > 0.04 && magnitude > 1.2 {
                        triggerRestart()
                    }
                }
            }

            if magnitude > 1.7 {
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
