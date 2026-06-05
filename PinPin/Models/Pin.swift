import SwiftData
import UIKit

@Model
final class Pin {
    var id: UUID
    var imageData: Data
    var imageFilename: String?
    var inspiration: String
    var createdAt: Date
    var projects: [Project]

    init(imageData: Data, inspiration: String = "", project: Project? = nil) {
        let id = UUID()
        let filename = ReferenceImageStore.storeReferenceImage(imageData, id: id)

        self.id = id
        self.imageFilename = filename
        self.imageData = filename == nil ? imageData : Data()
        self.inspiration = inspiration
        self.createdAt = Date()
        self.projects = project.map { [$0] } ?? []
    }

    var uiImage: UIImage? {
        ReferenceImageStore.image(named: imageFilename) ?? UIImage(data: imageData)?.normalizedForDisplay()
    }

    var storedImageData: Data {
        ReferenceImageStore.imageData(named: imageFilename) ?? imageData
    }

    @discardableResult
    func ensureImageFileBacked() -> Bool {
        guard imageFilename == nil, !imageData.isEmpty else { return false }
        imageFilename = ReferenceImageStore.storeReferenceImage(imageData, id: id)
        if imageFilename != nil {
            imageData = Data()
            return true
        }
        return false
    }
}

extension Pin {
    func isInProject(_ project: Project?) -> Bool {
        if let project {
            return projects.contains { $0.id == project.id }
        }
        return projects.isEmpty
    }

    func addToProject(_ project: Project) {
        if !projects.contains(where: { $0.id == project.id }) {
            projects.append(project)
        }
    }

    func removeFromProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
    }
}

extension UIImage {
    func normalizedForDisplay() -> UIImage {
        guard imageOrientation != .up || scale != 1 else { return self }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func normalizedJPEGData(compressionQuality: CGFloat = 0.9) -> Data? {
        normalizedForDisplay().jpegData(compressionQuality: compressionQuality)
    }
}
