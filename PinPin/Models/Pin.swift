import SwiftData
import UIKit

@Model
final class Pin {
    var id: UUID
    var imageData: Data
    var inspiration: String
    var createdAt: Date
    var project: Project?

    init(imageData: Data, inspiration: String = "", project: Project? = nil) {
        self.id = UUID()
        self.imageData = imageData
        self.inspiration = inspiration
        self.createdAt = Date()
        self.project = project
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }
}
