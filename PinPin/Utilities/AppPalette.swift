import SwiftUI

enum AppPalette {
    static let deepCharcoal = Color(red: 0.122, green: 0.122, blue: 0.137)
    static let warmOffWhite = Color(red: 0.961, green: 0.953, blue: 0.937)
    static let mutedIndigo = Color(red: 0.298, green: 0.353, blue: 0.447)
    static let dustyTerracotta = Color(red: 0.769, green: 0.416, blue: 0.290)
    static let oliveGreen = Color(red: 0.478, green: 0.545, blue: 0.353)
    static let softOchre = Color(red: 0.839, green: 0.659, blue: 0.353)
    static let coolGray = Color(red: 0.659, green: 0.659, blue: 0.678)

    static let vanDykeBrown = deepCharcoal
    static let rawUmber = mutedIndigo
    static let titaniumWhite = warmOffWhite
    static let warmTitaniumWhite = warmOffWhite
    static let mauve = mutedIndigo
    static let mutedMauve = dustyTerracotta
    static let surface = warmOffWhite
    static let raisedSurface = Color(red: 0.985, green: 0.979, blue: 0.965)
    static let selectedSurface = softOchre.opacity(0.26)
    static let hairline = coolGray.opacity(0.30)
    static let secondaryText = mutedIndigo.opacity(0.76)
}
