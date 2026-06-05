import SwiftUI
import SwiftData
import Foundation

@main
struct AtelierApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Pin.self, SavedColor.self, Project.self])
        container = Self.makeLocalContainer(schema: schema)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .tint(AppPalette.mauve)
        }
    }

    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
        let config = localModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Failed to open local SwiftData store: \(error)")
            resetLocalStore()
        }

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Failed to reopen local SwiftData store after reset: \(error)")
        }

        do {
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: memoryConfig)
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

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
        let storeDirectoryURL = storeURL.deletingLastPathComponent()
        let storePrefix = storeURL.lastPathComponent

        if let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: storeDirectoryURL,
            includingPropertiesForKeys: nil
        ) {
            for fileURL in fileURLs where fileURL.lastPathComponent.hasPrefix(storePrefix) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
