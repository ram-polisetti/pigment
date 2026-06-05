import SwiftUI
import SwiftData

@main
struct AtelierApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Pin.self, SavedColor.self, Project.self])
#if DEBUG
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
#else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.atelier.references")
            )
#endif
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .tint(AppPalette.mauve)
        }
    }
}
