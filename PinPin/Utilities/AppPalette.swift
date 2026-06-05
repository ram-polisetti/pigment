import SwiftUI

enum AppPalette {
    static let ink = Color(red: 0.055, green: 0.047, blue: 0.075)
    static let graphite = Color(red: 0.24, green: 0.225, blue: 0.29)
    static let linen = Color(red: 1.0, green: 0.985, blue: 0.955)
    static let plaster = Color(red: 0.955, green: 0.935, blue: 0.90)
    static let oxideRed = Color(red: 1.0, green: 0.24, blue: 0.19)
    static let ochre = Color(red: 1.0, green: 0.67, blue: 0.06)
    static let mutedIris = Color(red: 0.18, green: 0.25, blue: 1.0)
    static let orchid = Color(red: 0.80, green: 0.18, blue: 0.92)

    static let vanDykeBrown = ink
    static let rawUmber = graphite
    static let titaniumWhite = linen
    static let warmTitaniumWhite = linen
    static let mauve = mutedIris
    static let mutedMauve = mutedIris
    static let surface = linen
    static let raisedSurface = plaster
    static let selectedSurface = Color(red: 1.0, green: 0.81, blue: 0.27)
    static let hairline = ink.opacity(0.18)
    static let secondaryText = graphite.opacity(0.82)
}
