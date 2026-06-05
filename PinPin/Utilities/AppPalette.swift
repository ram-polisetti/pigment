import SwiftUI

enum AppPalette {
    static let warmLinen = Color(red: 0.957, green: 0.941, blue: 0.910)
    static let gessoWhite = Color(red: 0.984, green: 0.973, blue: 0.953)
    static let atelierBlack = Color(red: 0.153, green: 0.153, blue: 0.149)
    static let atelierBlue = Color(red: 0.086, green: 0.216, blue: 0.290)
    static let yellowOchre = Color(red: 0.784, green: 0.604, blue: 0.239)
    static let burntSienna = Color(red: 0.659, green: 0.361, blue: 0.243)
    static let umberOlive = Color(red: 0.431, green: 0.412, blue: 0.322)
    static let stoneGray = Color(red: 0.718, green: 0.690, blue: 0.643)

    static let vanDykeBrown = atelierBlack
    static let rawUmber = atelierBlue
    static let titaniumWhite = warmLinen
    static let warmTitaniumWhite = warmLinen
    static let mauve = atelierBlue
    static let mutedMauve = burntSienna
    static let surface = warmLinen
    static let raisedSurface = gessoWhite
    static let selectedSurface = yellowOchre.opacity(0.24)
    static let hairline = stoneGray.opacity(0.32)
    static let secondaryText = umberOlive.opacity(0.86)
}
