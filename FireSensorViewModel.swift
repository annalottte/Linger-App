import Foundation
import CoreMotion
import Combine
import UIKit

enum FireState: String {
    case burning
    case warning
    case extinguished
}

enum FaceOrientation: String {
    case faceUp
    case faceDown
    case vertical
    case unknown
}

struct FireEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

@MainActor
final class FireSensorViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published var isSessionRunning = false
    @Published var fireState: FireState = .extinguished
    @Published var graceRemaining: Int = 0

    @Published var appLifecycle: String = "active"
    @Published var orientation: FaceOrientation = .unknown
    @Published var motionMagnitude: Double = 0.0
    @Published var isDeviceMoving = false

    @Published var events: [FireEvent] = []

    // MARK: - Tunables (adjust after testing)
    private let sampleInterval: TimeInterval = 0.2         // 5 Hz
    private let movingThreshold: Double = 0.18             // tune on device
    private let graceSeconds: Int = 10

    // MARK: - Internals
    private let motionManager = CMMotionManager()
    private var graceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var hasWarnedThisIncident = false

    // app active/inactive tracking
    private var isAppActive = true

    init() {
        bindLifecycleNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopSession()
    }

    // MARK: - Public API
    func toggleSession() {
        isSessionRunning ? stopSession() : startSession()
    }

    func startSession() {
        guard !isSessionRunning else { return }
        isSessionRunning = true
        fireState = .burning
        graceRemaining = 0
        hasWarnedThisIncident = false
        log("Session started. Fire is burning.")
        startMotion()
    }

    func stopSession() {
        guard isSessionRunning else { return }
        isSessionRunning = false
        stopMotion()
        cancelGraceTimer()
        fireState = .extinguished
        graceRemaining = 0
        hasWarnedThisIncident = false
        log("Session stopped. Fire extinguished.")
    }

    // MARK: - Lifecycle
    private func bindLifecycleNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAppActive = true
                self.appLifecycle = "active"
                self.log("App became active.")
                self.evaluateSignals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAppActive = false
                self.appLifecycle = "inactive"
                self.log("App will resign active.")
                self.evaluateSignals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAppActive = false
                self.appLifecycle = "background"
                self.log("App entered background.")
                self.evaluateSignals()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.log("App will enter foreground.")
            }
            .store(in: &cancellables)
    }

    // MARK: - Motion
    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            log("DeviceMotion unavailable on this device.")
            return
        }

        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            if let error {
                self.log("Motion error: \(error.localizedDescription)")
                return
            }
            guard let motion else { return }
            self.processMotion(motion)
        }
        log("Motion updates started.")
    }

    private func stopMotion() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            log("Motion updates stopped.")
        }
    }

    private func processMotion(_ motion: CMDeviceMotion) {
        let g = motion.gravity
        let userAcc = motion.userAcceleration

        // Orientation inference from gravity vector:
        // z ~ -1 => face up ; z ~ +1 => face down ; otherwise vertical-ish
        if g.z < -0.75 {
            orientation = .faceUp
        } else if g.z > 0.75 {
            orientation = .faceDown
        } else if abs(g.y) > 0.6 || abs(g.x) > 0.6 {
            orientation = .vertical
        } else {
            orientation = .unknown
        }

        // motion magnitude from user acceleration
        let magnitude = sqrt(userAcc.x * userAcc.x + userAcc.y * userAcc.y + userAcc.z * userAcc.z)
        motionMagnitude = magnitude
        isDeviceMoving = magnitude > movingThreshold

        evaluateSignals()
    }

    // MARK: - Signal to fire-state logic
    private func evaluateSignals() {
        guard isSessionRunning else { return }

        // "Good" conditions for V0:
        // - App active
        // - Device face down
        // - Not moving significantly
        let healthy = isAppActive && orientation == .faceDown && !isDeviceMoving

        if healthy {
            recoverToBurningIfNeeded()
            return
        }

        // Not healthy -> warning with grace, then extinguish
        beginWarningIfNeeded()
    }

    private func beginWarningIfNeeded() {
        if fireState == .extinguished { return }

        if fireState != .warning {
            fireState = .warning
            graceRemaining = graceSeconds
            if !hasWarnedThisIncident {
                log("Fire warning: flickering (\(graceSeconds)s grace).")
                hasWarnedThisIncident = true
            }
            startGraceTimer()
        }
    }

    private func recoverToBurningIfNeeded() {
        if fireState == .warning {
            cancelGraceTimer()
            fireState = .burning
            graceRemaining = 0
            hasWarnedThisIncident = false
            log("Fire saved. Back to burning.")
        } else if fireState == .extinguished {
            // For this harness, keep extinguished terminal until manual restart.
            // (You can change this later if you want auto-restart behavior.)
        } else {
            fireState = .burning
        }
    }

    private func startGraceTimer() {
        cancelGraceTimer()
        graceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            Task { @MainActor in
                guard self.fireState == .warning else {
                    timer.invalidate()
                    return
                }

                self.graceRemaining -= 1

                if self.graceRemaining <= 0 {
                    timer.invalidate()
                    self.fireState = .extinguished
                    self.log("Fire extinguished.")
                }
            }
        }
    }

    private func cancelGraceTimer() {
        graceTimer?.invalidate()
        graceTimer = nil
    }

    // MARK: - Logging
    private func log(_ message: String) {
        let event = FireEvent(timestamp: Date(), message: message)
        events.insert(event, at: 0)

        // Optional: keep log bounded
        if events.count > 250 {
            events.removeLast(events.count - 250)
        }

        // Also print for Xcode console
        print("[FireSensor] \(message)")
    }
}
