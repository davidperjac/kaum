import Foundation
import Observation
import SwiftData

/// One morning, from ringing to complete. Owns the DailyEntry, drives the
/// step progression, and talks to AlarmKit + the sound player.
@Observable
@MainActor
final class MorningSession {

    enum Step {
        case ringing            // verse hero + mode buttons, sound playing
        case verifying          // camera / mic / keyboard active
        case verified           // bloom + check
        case prayer
        case devotional
        case journal
        case complete
    }

    let alarmModelID: UUID?
    let verse: VerseRef
    let verseText: String
    let anchors: VerseAnchors
    let sound: AlarmSound
    let isDemo: Bool

    private(set) var step: Step = .ringing
    private(set) var mode: VerifyMode
    private(set) var snoozesUsed = 0
    private(set) var startedAt = Date()
    private(set) var milestoneHit: Int?

    var verification: VerificationSession?

    /// Called when the whole flow finishes (complete screen dismissed).
    var onFinished: (() -> Void)?

    init(
        alarmModelID: UUID?,
        verse: VerseRef,
        verseText: String,
        anchors: VerseAnchors,
        mode: VerifyMode,
        sound: AlarmSound,
        isDemo: Bool = false
    ) {
        self.alarmModelID = alarmModelID
        self.verse = verse
        self.verseText = verseText
        self.anchors = anchors
        self.mode = mode
        self.sound = sound
        self.isDemo = isDemo
    }

    var canSnooze: Bool {
        !isDemo && snoozesUsed < KoumConfig.maxSnoozes
    }

    // MARK: - Ringing

    func startRinging() {
        AlarmSoundPlayer.shared.startRinging(
            sound: sound,
            volumeCap: isDemo ? 0.55 : 1.0,
            ramp: true
        )
    }

    /// User picked (or confirmed) a mode from the ringing screen.
    func beginVerification(mode: VerifyMode? = nil) {
        if let mode { self.mode = mode }
        let session = VerificationSession(
            target: verse, anchors: anchors, mode: self.mode, isDemo: isDemo)
        session.onPassed = { [weak self] usedEscapeHatch in
            self?.handleVerified(usedEscapeHatch: usedEscapeHatch)
        }
        verification = session
        step = .verifying
    }

    /// Switch to type mode mid-verification (escape hatch step 4).
    func switchToType() {
        beginVerification(mode: .type)
    }

    func snooze(context: ModelContext) {
        guard canSnooze, let id = alarmModelID else { return }
        snoozesUsed += 1
        AlarmSoundPlayer.shared.stop()
        if let model = try? context.fetch(FetchDescriptor<AlarmModel>(
            predicate: #Predicate { $0.id == id })).first {
            Task {
                try? await AlarmService.shared.scheduleSnooze(
                    for: model,
                    minutes: KoumConfig.snoozeMinutes,
                    verseReference: verse.display
                )
            }
        }
        onFinished?()
    }

    // MARK: - Verified

    private func handleVerified(usedEscapeHatch: Bool) {
        // Silence FIRST. The cut is the reward.
        AlarmSoundPlayer.shared.stop()
        if let id = alarmModelID {
            AlarmService.shared.stopRinging(id)
        }
        recordVerification(usedEscapeHatch: usedEscapeHatch)
        step = .verified
    }

    private var modelContext: ModelContext?

    func attach(context: ModelContext) {
        modelContext = context
    }

    private func recordVerification(usedEscapeHatch: Bool) {
        guard !isDemo, let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let entry: DailyEntry
        if let existing = try? context.fetch(FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today })).first {
            entry = existing
        } else {
            entry = DailyEntry(date: Date(), verse: verse)
            context.insert(entry)
        }
        entry.verified = true
        entry.verifyModeRaw = mode.rawValue
        entry.attempts = (verification?.failedAttempts ?? 0) + 1
        entry.usedEscapeHatch = usedEscapeHatch
        entry.completedAt = Date()
        milestoneHit = StreakService.recordCompletion(on: Date(), in: context)
        try? context.save()
    }

    // MARK: - Progression

    func advanceFromVerified() {
        // The demo proves the mechanic and stops; the full flow is for real
        // mornings.
        step = isDemo ? .complete : .prayer
    }

    func savePrayer(_ text: String) {
        defer { step = .devotional }
        guard !isDemo, let context = modelContext,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        context.insert(PrayerEntry(text: text, verse: verse))
        try? context.save()
    }

    func skipPrayer() { step = .devotional }

    func advanceFromDevotional() { step = .journal }

    func saveJournal(_ text: String, prompt: String) {
        defer { step = .complete }
        guard !isDemo, let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        guard let entry = try? context.fetch(FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today })).first else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            entry.journalText = trimmed
            entry.journalPrompt = prompt
        }
        try? context.save()
    }

    func skipJournal() { step = .complete }

    func finish() {
        onFinished?()
    }
}
