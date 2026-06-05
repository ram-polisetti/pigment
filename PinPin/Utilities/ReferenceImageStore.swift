import Foundation
import UIKit

enum ReferenceImageStore {
    private static let syncFolderName = "AtelierSync"
    private static let referencesFolderName = "references"

    static var syncRootURL: URL {
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = applicationSupportURL.appending(path: syncFolderName, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var referencesURL: URL {
        let url = syncRootURL.appending(path: referencesFolderName, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func storeReferenceImage(_ data: Data, id: UUID = UUID()) -> String? {
        let filename = "\(id.uuidString).\(fileExtension(for: data))"
        let url = referencesURL.appending(path: filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("Failed to write reference image file: \(error)")
            return nil
        }
    }

    static func imageData(named filename: String?) -> Data? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = referencesURL.appending(path: filename)
        return try? Data(contentsOf: url)
    }

    static func image(named filename: String?) -> UIImage? {
        guard let data = imageData(named: filename) else { return nil }
        return UIImage(data: data)?.normalizedForDisplay()
    }

    static func deleteReferenceImage(named filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? FileManager.default.removeItem(at: referencesURL.appending(path: filename))
    }

    private static func fileExtension(for data: Data) -> String {
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
        }
        if bytes.count >= 12,
           bytes[4...7] == [0x66, 0x74, 0x79, 0x70],
           bytes[8...11] == [0x68, 0x65, 0x69, 0x63] {
            return "heic"
        }
        return "image"
    }
}
