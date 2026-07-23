import Foundation
import SwiftData
import Testing
@testable import Koum

@Suite @MainActor struct StreakTests {

    private func freshContext() throws -> ModelContext {
        let schema = Schema([AlarmModel.self, DailyEntry.self, PrayerEntry.self, StreakState.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        return ModelContext(container)
    }

    private func day(_ offset: Int, from base: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: base)!
    }

    @Test func consecutiveDaysIncrement() throws {
        let ctx = try freshContext()
        let base = Date()
        _ = StreakService.recordCompletion(on: day(-2, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: day(-1, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: base, in: ctx)
        #expect(StreakService.state(in: ctx).current == 3)
        #expect(StreakService.state(in: ctx).longest == 3)
    }

    @Test func sameDayCountsOnce() throws {
        let ctx = try freshContext()
        _ = StreakService.recordCompletion(on: Date(), in: ctx)
        _ = StreakService.recordCompletion(on: Date(), in: ctx)
        #expect(StreakService.state(in: ctx).current == 1)
    }

    @Test func oneMissedDayIsBridgedByMonthlyFreeze() throws {
        let ctx = try freshContext()
        let base = Date()
        _ = StreakService.recordCompletion(on: day(-3, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: day(-2, from: base), in: ctx)
        // day(-1) missed entirely
        _ = StreakService.recordCompletion(on: base, in: ctx)
        let state = StreakService.state(in: ctx)
        #expect(state.current == 3, "freeze should bridge a single missed day")
        #expect(state.freezeSpentMonth != nil)
    }

    @Test func secondMissInSameMonthResets() throws {
        let ctx = try freshContext()
        let base = Date()
        _ = StreakService.recordCompletion(on: day(-6, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: day(-4, from: base), in: ctx) // gap: freeze spent
        _ = StreakService.recordCompletion(on: day(-3, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: day(-1, from: base), in: ctx) // another gap
        let state = StreakService.state(in: ctx)
        // Note: both gaps fall in the same calendar month only most of the
        // time; when they straddle a month boundary the second freeze is
        // legitimately available. Accept either outcome accordingly.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let sameMonth = formatter.string(from: day(-4, from: base)) == formatter.string(from: day(-1, from: base))
        if sameMonth {
            #expect(state.current == 1, "second miss in a month resets; the new run starts at 1")
        } else {
            #expect(state.current == 4)
        }
    }

    @Test func longGapResets() throws {
        let ctx = try freshContext()
        let base = Date()
        _ = StreakService.recordCompletion(on: day(-10, from: base), in: ctx)
        _ = StreakService.recordCompletion(on: base, in: ctx)
        #expect(StreakService.state(in: ctx).current == 1)
    }

    @Test func milestonesFire() throws {
        let ctx = try freshContext()
        let base = Date()
        var milestone: Int?
        for offset in stride(from: -2, through: 0, by: 1) {
            milestone = StreakService.recordCompletion(on: day(offset, from: base), in: ctx)
        }
        #expect(milestone == 3)
    }
}
