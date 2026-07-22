import Foundation
import Observation

/// Orchestrates one verification attempt-session: local matching, LLM
/// escalation, attempt counting, and the mandatory escape hatch. The alarm
/// must never become undismissable.
@Observable
@MainActor
final class VerificationSession {

    enum Stage {
        case working
        case passed(usedEscapeHatch: Bool)
    }

    let target: VerseRef
    let anchors: VerseAnchors
    let verseTokens: Set<String>
    let mode: VerifyMode
    /// Demo mode (onboarding): auto-passes after 2 failed attempts.
    let isDemo: Bool

    private(set) var stage: Stage = .working
    private(set) var failedAttempts = 0
    private(set) var startedAt = Date()
    private(set) var escalating = false

    /// Guidance line for the scan overlay, escalating with attempts/time.
    private(set) var guidance = "Point at the page"
    /// Show the "Type it instead" switch (attempt 4+).
    private(set) var offersTypeSwitch = false
    /// Show "I'll take your word for it" (attempt 5+ or 45s of failures).
    private(set) var offersEscapeHatch = false
    /// Demo-only soft pass message.
    private(set) var demoAutoPassed = false

    private var matcher: LocalMatcher
    private let escalator = GeminiEscalator()
    private var lastEscalation = Date.distantPast

    var onPassed: ((_ usedEscapeHatch: Bool) -> Void)?

    init(target: VerseRef, anchors: VerseAnchors, mode: VerifyMode, isDemo: Bool = false) {
        self.target = target
        self.anchors = anchors
        self.mode = mode
        self.isDemo = isDemo
        self.verseTokens = LocalMatcher.verseTokens(for: target)
        switch mode {
        case .speak:
            self.matcher = LocalMatcher.forSpeech()
        case .scan:
            self.matcher = GeminiEscalator.isConfigured ? LocalMatcher() : LocalMatcher.offline()
        case .type:
            self.matcher = LocalMatcher()
        }
    }

    // MARK: - Scan / speak text evaluation

    /// Evaluate accumulated recognized text. Returns true when passed.
    @discardableResult
    func evaluate(text: String) -> Bool {
        guard case .working = stage else { return true }
        let result = matcher.evaluate(
            rawText: text, target: target, anchors: anchors, verseTokens: verseTokens)

        switch result.decision {
        case .pass:
            pass(escapeHatch: false)
            return true
        case .escalate where mode == .scan:
            maybeEscalate(text: text)
            return false
        default:
            return false
        }
    }

    private func maybeEscalate(text: String) {
        guard !escalating, Date().timeIntervalSince(lastEscalation) > 4 else { return }
        escalating = true
        lastEscalation = Date()
        Task {
            let outcome = await escalator.identify(ocrText: text, target: target)
            self.escalating = false
            if case .pass = outcome, case .working = self.stage {
                self.pass(escapeHatch: false)
            }
        }
    }

    // MARK: - Attempts & escape hatch

    /// Record a failed capture attempt (no match after a sustained try).
    func recordFailedAttempt() {
        guard case .working = stage else { return }
        failedAttempts += 1
        KoumHaptics.verificationFailed()

        if isDemo, failedAttempts >= 2 {
            demoAutoPassed = true
            pass(escapeHatch: false)
            return
        }
        updateGuidance()
    }

    /// Called periodically so time-based escalation works even without
    /// discrete failures.
    func tick() {
        guard case .working = stage else { return }
        let elapsed = Date().timeIntervalSince(startedAt)
        if elapsed > 12, failedAttempts == 0 {
            failedAttempts = 1 // counts a long fruitless stretch as an attempt
        }
        updateGuidance()
        if elapsed > 45 { offersEscapeHatch = true }
        if elapsed > 25 { offersTypeSwitch = true }
    }

    private func updateGuidance() {
        let elapsed = Date().timeIntervalSince(startedAt)
        switch (failedAttempts, elapsed) {
        case (0, ..<6):
            guidance = "Point at the page"
        case (0...1, _), (_, ..<10):
            guidance = "Get the whole page in frame"
        case (2, _):
            guidance = "Try moving closer to a light"
        default:
            guidance = "Hold steady — or type it instead"
        }
        if failedAttempts >= 3 { offersTypeSwitch = true }
        if failedAttempts >= 4 { offersEscapeHatch = true }
    }

    /// "I'll take your word for it." Still counts for the streak; logged for
    /// telemetry so the matcher can improve.
    func useEscapeHatch() {
        pass(escapeHatch: true)
    }

    /// Type mode passes through its own character-similarity check.
    func typePassed() {
        pass(escapeHatch: false)
    }

    private func pass(escapeHatch: Bool) {
        guard case .working = stage else { return }
        stage = .passed(usedEscapeHatch: escapeHatch)
        // The bloom plays the composed swell; no generator haptic here.
        onPassed?(escapeHatch)
    }
}
