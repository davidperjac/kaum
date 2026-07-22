import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct KoumWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextAlarmWidget()
        VerseWidget()
        KoumAlarmLiveActivity()
    }
}

// MARK: - Shared timeline

struct KoumEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct KoumProvider: TimelineProvider {
    func placeholder(in context: Context) -> KoumEntry {
        KoumEntry(date: .now, snapshot: WidgetSnapshot(
            nextAlarmDate: .now.addingTimeInterval(8 * 3600),
            streak: 12,
            completedToday: false,
            verseReference: "Psalm 143:8",
            verseText: "Cause me to hear thy lovingkindness in the morning; for in thee do I trust."
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (KoumEntry) -> Void) {
        completion(KoumEntry(date: .now, snapshot: WidgetSnapshot.load(appGroupID: "group.dptech.koum")))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KoumEntry>) -> Void) {
        let entry = KoumEntry(date: .now, snapshot: WidgetSnapshot.load(appGroupID: "group.dptech.koum"))
        // Refresh around the next alarm, else hourly.
        let refresh = entry.snapshot.nextAlarmDate.flatMap { $0 > .now ? $0 : nil }
            ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(min(refresh, .now.addingTimeInterval(3600)))))
    }
}

// MARK: - Next alarm + streak (lock screen & small)

struct NextAlarmWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KoumNextAlarm", provider: KoumProvider()) { entry in
            NextAlarmWidgetView(entry: entry)
                .containerBackground(Color(red: 0.039, green: 0.055, blue: 0.102), for: .widget)
        }
        .configurationDisplayName("Next alarm")
        .description("Your next alarm and streak.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

struct NextAlarmWidgetView: View {
    let entry: KoumEntry
    @Environment(\.widgetFamily) private var family

    private var amber: Color { Color(red: 0.910, green: 0.651, blue: 0.341) }
    private var bone: Color { Color(red: 0.949, green: 0.937, blue: 0.910) }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let next = entry.snapshot.nextAlarmDate {
                Text("Koum \(next.formatted(date: .omitted, time: .shortened)) · \(entry.snapshot.streak)")
            } else {
                Text("Koum — no alarm")
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                if let next = entry.snapshot.nextAlarmDate {
                    Text(next.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 22, weight: .light, design: .serif))
                    Text("\(entry.snapshot.streak) mornings")
                        .font(.system(size: 12))
                        .opacity(0.7)
                } else {
                    Text("No alarm set")
                        .font(.system(size: 14, design: .serif))
                }
            }

        default:
            VStack(alignment: .leading, spacing: 4) {
                if entry.snapshot.completedToday {
                    Label("Done", systemImage: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.420, green: 0.686, blue: 0.573))
                } else if let next = entry.snapshot.nextAlarmDate {
                    Text(next.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundStyle(bone)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 11))
                        .foregroundStyle(amber)
                    Text("\(entry.snapshot.streak)")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(amber)
                    Text(entry.snapshot.streak == 1 ? "morning" : "mornings")
                        .font(.system(size: 11))
                        .foregroundStyle(bone.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Verse widget (home screen)

struct VerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KoumVerse", provider: KoumProvider()) { entry in
            VerseWidgetView(entry: entry)
                .containerBackground(Color(red: 0.039, green: 0.055, blue: 0.102), for: .widget)
        }
        .configurationDisplayName("Today's verse")
        .description("The verse once your morning is complete; your alarm before.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct VerseWidgetView: View {
    let entry: KoumEntry

    private var amber: Color { Color(red: 0.910, green: 0.651, blue: 0.341) }
    private var bone: Color { Color(red: 0.949, green: 0.937, blue: 0.910) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.snapshot.completedToday, !entry.snapshot.verseText.isEmpty {
                Text(entry.snapshot.verseReference.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .kerning(1.2)
                    .foregroundStyle(amber)
                Text(entry.snapshot.verseText)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(bone)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
            } else if let next = entry.snapshot.nextAlarmDate {
                Text("TOMORROW".uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .kerning(1.2)
                    .foregroundStyle(amber)
                Text(next.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .foregroundStyle(bone)
                Text(entry.snapshot.verseReference)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(bone.opacity(0.7))
            } else {
                Text("KOUM")
                    .font(.system(size: 9, weight: .medium))
                    .kerning(1.2)
                    .foregroundStyle(amber)
                Text("Set your alarm")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(bone)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Alarm Live Activity (AlarmKit countdown / alert presentation)

struct KoumAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<KoumAlarmMetadata>.self) { context in
            // Lock Screen presentation
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.metadata?.verseReference ?? "Koum")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                    Text("Open your Bible to turn it off")
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
                Spacer()
                Image(systemName: "sunrise")
                    .foregroundStyle(Color(red: 0.910, green: 0.651, blue: 0.341))
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.039, green: 0.055, blue: 0.102))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sunrise")
                        .foregroundStyle(Color(red: 0.910, green: 0.651, blue: 0.341))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.metadata?.verseReference ?? "Koum")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                }
            } compactLeading: {
                Image(systemName: "sunrise")
                    .foregroundStyle(Color(red: 0.910, green: 0.651, blue: 0.341))
            } compactTrailing: {
                Text(context.attributes.metadata?.verseReference ?? "")
                    .font(.system(size: 11))
            } minimal: {
                Image(systemName: "sunrise")
                    .foregroundStyle(Color(red: 0.910, green: 0.651, blue: 0.341))
            }
        }
    }
}
