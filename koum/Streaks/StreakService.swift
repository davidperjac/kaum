import Foundation
import SwiftData

/// Streak rules:
/// - The streak counts mornings completed (verification within the grace
///   window). Prayer, devotional, journal never gate it.
/// - One automatic freeze per month: miss a single day and the streak
///   survives; the user is told gently.
/// - No shame. A broken streak says "Start again tomorrow", never a red X.
@MainActor
enum StreakService {

    static let milestones = [3, 7, 14, 30, 60, 100, 365]

    /// Short verse shown at each milestone.
    static func milestoneVerse(for milestone: Int) -> (ref: String, text: String) {
        switch milestone {
        case 3: ("Lamentations 3:23", "They are new every morning: great is thy faithfulness.")
        case 7: ("Psalm 5:3", "My voice shalt thou hear in the morning, O Lord.")
        case 14: ("Psalm 119:147", "I rose before the dawning of the morning, and cried: I hoped in thy word.")
        case 30: ("Psalm 90:14", "O satisfy us early with thy mercy; that we may rejoice and be glad all our days.")
        case 60: ("Isaiah 50:4", "He wakeneth morning by morning, he wakeneth mine ear to hear.")
        case 100: ("Psalm 57:8", "Awake up, my glory; awake, psaltery and harp: I myself will awake early.")
        case 365: ("Psalm 65:8", "Thou makest the outgoings of the morning and evening to rejoice.")
        default: ("Psalm 118:24", "This is the day which the Lord hath made; we will rejoice and be glad in it.")
        }
    }

    static func state(in context: ModelContext) -> StreakState {
        if let existing = try? context.fetch(FetchDescriptor<StreakState>()).first {
            return existing
        }
        let fresh = StreakState()
        context.insert(fresh)
        return fresh
    }

    /// Record a completed morning. Returns the milestone hit, if any.
    @discardableResult
    static func recordCompletion(on date: Date, in context: ModelContext) -> Int? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let state = state(in: context)

        if let last = state.lastCompleted {
            let lastDay = cal.startOfDay(for: last)
            let gap = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            switch gap {
            case 0:
                return nil // already counted today
            case 1:
                state.current += 1
            case 2:
                // One missed day: spend the monthly freeze if available.
                if spendFreezeIfAvailable(state: state, today: today) {
                    state.current += 1
                } else {
                    state.current = 1
                }
            default:
                state.current = 1
            }
        } else {
            state.current = 1
        }

        state.lastCompleted = today
        state.longest = max(state.longest, state.current)
        try? context.save()

        return milestones.contains(state.current) ? state.current : nil
    }

    private static func spendFreezeIfAvailable(state: StreakState, today: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: today)
        guard state.freezeSpentMonth != month else { return false }
        state.freezeSpentMonth = month
        state.freezeUsedDate = today
        return true
    }

    /// Current streak as it stands *now* (accounts for a broken chain that
    /// hasn't been re-recorded yet). Also reports whether a freeze is
    /// currently bridging yesterday.
    static func effectiveStreak(in context: ModelContext, now: Date = Date()) -> (current: Int, broken: Bool) {
        let cal = Calendar.current
        let state = state(in: context)
        guard let last = state.lastCompleted else { return (0, false) }
        let gap = cal.dateComponents(
            [.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day ?? 0
        switch gap {
        case 0, 1:
            return (state.current, false)
        case 2:
            // Yesterday missed; freeze may still save it if today completes.
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            let canFreeze = state.freezeSpentMonth != formatter.string(from: now)
            return canFreeze ? (state.current, false) : (0, true)
        default:
            return (0, true)
        }
    }
}
