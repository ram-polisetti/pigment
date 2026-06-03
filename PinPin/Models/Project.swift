import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Pin.project) var pins: [Pin]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.pins = []
    }
}
