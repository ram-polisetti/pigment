import SwiftData
import SwiftUI

@Model
final class SavedColor {
    var id: UUID
    var hex: String
    var name: String
    var createdAt: Date

    init(hex: String, name: String) {
        self.id = UUID()
        self.hex = hex
        self.name = name
        self.createdAt = Date()
    }
}
