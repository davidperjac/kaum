import SwiftData
import SwiftUI

@main
struct KoumApp: App {

    let container: ModelContainer
    @State private var app = AppModel()
    @State private var subscriptions = SubscriptionManager()

    init() {
        let schema = Schema([
            AlarmModel.self, DailyEntry.self, PrayerEntry.self, StreakState.self,
        ])
        // Models are CloudKit-compatible; flip KoumConfig.cloudKitSyncEnabled
        // (and add the iCloud capability) to turn on private-database sync.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: KoumConfig.cloudKitSyncEnabled ? .automatic : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Never refuse to launch an alarm app over a store error; fall
            // back to an in-memory store rather than crash at 6am.
            container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }

        BibleStore.shared.preload()
        PlanStore.shared.preload()
        DevotionalStore.shared.preload()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(subscriptions)
        }
        .modelContainer(container)
    }
}
