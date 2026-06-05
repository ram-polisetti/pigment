import SwiftUI

enum AppPalette {
    static let ink = Color(red: 0.12, green: 0.105, blue: 0.13)
    static let graphite = Color(red: 0.32, green: 0.29, blue: 0.34)
    static let linen = Color(red: 0.99, green: 0.955, blue: 0.895)
    static let plaster = Color(red: 0.94, green: 0.89, blue: 0.80)
    static let oxideRed = Color(red: 0.78, green: 0.28, blue: 0.22)
    static let ochre = Color(red: 0.91, green: 0.62, blue: 0.18)
    static let mutedIris = Color(red: 0.42, green: 0.33, blue: 0.72)

    static let vanDykeBrown = ink
    static let rawUmber = graphite
    static let titaniumWhite = linen
    static let warmTitaniumWhite = linen
    static let mauve = oxideRed
    static let mutedMauve = mutedIris
    static let surface = linen
    static let raisedSurface = plaster
    static let selectedSurface = Color(red: 0.98, green: 0.80, blue: 0.55)
    static let hairline = ink.opacity(0.18)
    static let secondaryText = graphite.opacity(0.82)
}
