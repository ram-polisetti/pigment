import SwiftUI

enum AppPalette {
    static let ink = Color(red: 0.14, green: 0.13, blue: 0.14)
    static let graphite = Color(red: 0.35, green: 0.32, blue: 0.31)
    static let linen = Color(red: 0.965, green: 0.935, blue: 0.89)
    static let plaster = Color(red: 0.90, green: 0.865, blue: 0.81)
    static let oxideRed = Color(red: 0.61, green: 0.31, blue: 0.25)
    static let ochre = Color(red: 0.75, green: 0.54, blue: 0.25)
    static let mutedIris = Color(red: 0.49, green: 0.43, blue: 0.57)

    static let vanDykeBrown = ink
    static let rawUmber = graphite
    static let titaniumWhite = linen
    static let warmTitaniumWhite = linen
    static let mauve = oxideRed
    static let mutedMauve = mutedIris
    static let surface = linen
    static let raisedSurface = plaster
    static let selectedSurface = Color(red: 0.80, green: 0.735, blue: 0.66)
    static let hairline = ink.opacity(0.16)
    static let secondaryText = graphite.opacity(0.78)
}
