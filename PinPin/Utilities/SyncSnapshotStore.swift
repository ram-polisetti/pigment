import Foundation
import SwiftData

enum SyncSnapshotStore {
    private static let indexFilename = "atelier-index.json"

    static func writeSnapshot(from modelContext: ModelContext) {
        do {
            let projects = try modelContext.fetch(FetchDescriptor<Project>())
            let pins = try modelContext.fetch(FetchDescriptor<Pin>())
            let colors = try modelContext.fetch(FetchDescriptor<SavedColor>())
            let didMigrateImages = pins.reduce(false) { didMigrate, pin in
                pin.ensureImageFileBacked() || didMigrate
            }
            if didMigrateImages {
                try? modelContext.save()
            }

            let snapshot = AtelierSyncSnapshot(
                exportedAt: Date(),
                projects: projects.map { project in
                    AtelierProjectSnapshot(
                        id: project.id,
                        name: project.name,
                        createdAt: project.createdAt
                    )
                },
                references: pins.map { pin in
                    AtelierReferenceSnapshot(
                        id: pin.id,
                        imageFilename: pin.imageFilename,
                        inspiration: pin.inspiration,
                        createdAt: pin.createdAt,
                        projectIDs: pin.projects.map(\.id)
                    )
                },
                colors: colors.map { saved in
                    AtelierColorSnapshot(
                        id: saved.id,
                        hex: saved.hex,
                        name: saved.name,
                        createdAt: saved.createdAt,
                        projectID: saved.project?.id,
                        sourcePinIDs: saved.allSourcePins.map(\.id)
                    )
                }
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            print("Failed to write Atelier sync snapshot: \(error)")
        }
    }

    static var indexURL: URL {
        ReferenceImageStore.syncRootURL.appending(path: indexFilename)
    }
}

extension ModelContext {
    func saveAndWriteAtelierSnapshot() {
        do {
            try save()
            SyncSnapshotStore.writeSnapshot(from: self)
        } catch {
            print("Failed to save Atelier data: \(error)")
        }
    }
}

private struct AtelierSyncSnapshot: Codable {
    let version: Int
    let exportedAt: Date
    let projects: [AtelierProjectSnapshot]
    let references: [AtelierReferenceSnapshot]
    let colors: [AtelierColorSnapshot]

    init(
        version: Int = 1,
        exportedAt: Date,
        projects: [AtelierProjectSnapshot],
        references: [AtelierReferenceSnapshot],
        colors: [AtelierColorSnapshot]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.projects = projects
        self.references = references
        self.colors = colors
    }
}

private struct AtelierProjectSnapshot: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
}

private struct AtelierReferenceSnapshot: Codable {
    let id: UUID
    let imageFilename: String?
    let inspiration: String
    let createdAt: Date
    let projectIDs: [UUID]
}

private struct AtelierColorSnapshot: Codable {
    let id: UUID
    let hex: String
    let name: String
    let createdAt: Date
    let projectID: UUID?
    let sourcePinIDs: [UUID]
}
