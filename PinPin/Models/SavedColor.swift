import SwiftData
import SwiftUI

@Model
final class SavedColor {
    var id: UUID
    var hex: String
    var name: String
    var createdAt: Date
    var project: Project?
    var sourcePin: Pin?
    var sourcePins: [Pin]

    init(hex: String, name: String, project: Project? = nil, sourcePin: Pin? = nil) {
        self.id = UUID()
        self.hex = hex
        self.name = name
        self.createdAt = Date()
        self.project = project
        self.sourcePin = sourcePin
        self.sourcePins = sourcePin.map { [$0] } ?? []
    }
}

extension SavedColor {
    var allSourcePins: [Pin] {
        var pins = sourcePins
        if let sourcePin, !pins.contains(where: { $0.id == sourcePin.id }) {
            pins.insert(sourcePin, at: 0)
        }
        return pins
    }

    func containsSourcePin(_ pin: Pin) -> Bool {
        allSourcePins.contains { $0.id == pin.id }
    }

    func addSourcePin(_ pin: Pin) {
        if sourcePin == nil {
            sourcePin = pin
        }
        if !sourcePins.contains(where: { $0.id == pin.id }) {
            sourcePins.append(pin)
        }
    }

    func removeSourcePin(_ pin: Pin) {
        sourcePins.removeAll { $0.id == pin.id }
        if sourcePin?.id == pin.id {
            sourcePin = sourcePins.first
        }
    }
}
