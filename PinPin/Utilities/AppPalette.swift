import SwiftUI

enum AppPalette {
    static let ink = Color(red: 0.055, green: 0.055, blue: 0.075)
    static let graphite = Color(red: 0.24, green: 0.23, blue: 0.29)
    static let linen = Color(red: 1.0, green: 0.985, blue: 0.94)
    static let plaster = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let oxideRed = Color(red: 0.96, green: 0.18, blue: 0.12)
    static let ochre = Color(red: 1.0, green: 0.75, blue: 0.12)
    static let mutedIris = Color(red: 0.08, green: 0.22, blue: 0.76)

    static let vanDykeBrown = ink
    static let rawUmber = graphite
    static let titaniumWhite = linen
    static let warmTitaniumWhite = linen
    static let mauve = oxideRed
    static let mutedMauve = mutedIris
    static let surface = linen
    static let raisedSurface = plaster
    static let selectedSurface = Color(red: 1.0, green: 0.86, blue: 0.34)
    static let hairline = ink.opacity(0.18)
    static let secondaryText = graphite.opacity(0.82)
}
