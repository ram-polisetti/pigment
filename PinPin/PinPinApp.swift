import SwiftUI
import SwiftData
import Foundation

@main
struct AtelierApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Pin.self, SavedColor.self, Project.self])
#if DEBUG
            let config = Self.localModelConfiguration(schema: schema)
            do {
                container = try ModelContainer(for: schema, configurations: config)
            } catch {
                Self.resetLocalStore()
                container = try ModelContainer(for: schema, configurations: config)
            }
#else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.atelier.references")
            )
            container = try ModelContainer(for: schema, configurations: config)
#endif
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

#if DEBUG
    private static func localModelConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            url: localStoreURL(),
            cloudKitDatabase: .none
        )
    }

    private static func localStoreURL() -> URL {
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
        return applicationSupportURL.appending(path: "AtelierLocal.store")
    }

    private static func resetLocalStore() {
        let storeURL = localStoreURL()
        let fileURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
#endif
}
