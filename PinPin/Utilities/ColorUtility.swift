import SwiftUI

// MARK: - Color Data

struct NamedColor {
    let name: String
    let hex: String
}

/// A curated set of painter-friendly named colors.
let namedColors: [NamedColor] = [
    NamedColor(name: "Alizarin Crimson", hex: "#E32636"),
    NamedColor(name: "Cadmium Red", hex: "#E30022"),
    NamedColor(name: "Vermilion", hex: "#E34234"),
    NamedColor(name: "Scarlet", hex: "#FF2400"),
    NamedColor(name: "Indian Red", hex: "#CD5C5C"),
    NamedColor(name: "Venetian Red", hex: "#C80815"),
    NamedColor(name: "Rose Madder", hex: "#E32636"),
    NamedColor(name: "Burnt Sienna", hex: "#E97451"),
    NamedColor(name: "Cadmium Orange", hex: "#ED872D"),
    NamedColor(name: "Tangerine", hex: "#F28500"),
    NamedColor(name: "Amber", hex: "#FFBF00"),
    NamedColor(name: "Ochre", hex: "#CC7722"),
    NamedColor(name: "Raw Sienna", hex: "#D68A59"),
    NamedColor(name: "Yellow Ochre", hex: "#CB9D06"),
    NamedColor(name: "Cadmium Yellow", hex: "#FFF600"),
    NamedColor(name: "Lemon Yellow", hex: "#FFF44F"),
    NamedColor(name: "Naples Yellow", hex: "#FADA5E"),
    NamedColor(name: "Gold", hex: "#FFD700"),
    NamedColor(name: "Olive Green", hex: "#808000"),
    NamedColor(name: "Sap Green", hex: "#507D2A"),
    NamedColor(name: "Viridian", hex: "#40826D"),
    NamedColor(name: "Emerald", hex: "#50C878"),
    NamedColor(name: "Hooker's Green", hex: "#49796B"),
    NamedColor(name: "Phthalo Green", hex: "#123524"),
    NamedColor(name: "Teal", hex: "#008080"),
    NamedColor(name: "Cerulean Blue", hex: "#007BA7"),
    NamedColor(name: "Cobalt Blue", hex: "#0047AB"),
    NamedColor(name: "Ultramarine", hex: "#120A8F"),
    NamedColor(name: "Prussian Blue", hex: "#003153"),
    NamedColor(name: "Phthalo Blue", hex: "#000F89"),
    NamedColor(name: "Indigo", hex: "#4B0082"),
    NamedColor(name: "Lapis Lazuli", hex: "#26619C"),
    NamedColor(name: "Turquoise", hex: "#40E0D0"),
    NamedColor(name: "Manganese Violet", hex: "#7A4988"),
    NamedColor(name: "Dioxazine Purple", hex: "#5E3A7E"),
    NamedColor(name: "Mauve", hex: "#E0B0FF"),
    NamedColor(name: "Magenta", hex: "#FF00FF"),
    NamedColor(name: "Quinacridone Rose", hex: "#FF3599"),
    NamedColor(name: "Ivory Black", hex: "#231F20"),
    NamedColor(name: "Lamp Black", hex: "#1B1B1B"),
    NamedColor(name: "Payne's Gray", hex: "#536878"),
    NamedColor(name: "Titanium White", hex: "#F5F5F5"),
    NamedColor(name: "Zinc White", hex: "#FDFDFD"),
    NamedColor(name: "Warm White", hex: "#FDF5E6"),
    NamedColor(name: "Cream", hex: "#FFFDD0"),
    NamedColor(name: "Raw Umber", hex: "#826644"),
    NamedColor(name: "Burnt Umber", hex: "#8A3324"),
    NamedColor(name: "Sepia", hex: "#704214"),
    NamedColor(name: "Van Dyke Brown", hex: "#664228"),
    NamedColor(name: "Terre Verte", hex: "#56876D"),
    NamedColor(name: "Cobalt Turquoise", hex: "#3CD7B7"),
    NamedColor(name: "Cadmium Green", hex: "#006B3C"),
    NamedColor(name: "Naples Yellow Reddish", hex: "#F2C75C"),
    NamedColor(name: "Cadmium Lemon", hex: "#F0E442"),
    NamedColor(name: "Vandyke Brown", hex: "#4E3420"),
]

// MARK: - Color Conversion

extension Color {
    func hexString() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Color Identification

func closestNamedColor(to hex: String) -> NamedColor {
    let target = rgbFromHex(hex)
    var best = namedColors[0]
    var bestDist = Double.greatestFiniteMagnitude

    for named in namedColors {
        let c = rgbFromHex(named.hex)
        let dist = colorDistance(target, c)
        if dist < bestDist {
            bestDist = dist
            best = named
        }
    }
    return best
}

private func rgbFromHex(_ hex: String) -> (Double, Double, Double) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF)
    let g = Double((int >> 8) & 0xFF)
    let b = Double(int & 0xFF)
    return (r, g, b)
}

/// Weighted Euclidean distance in RGB, perceptually adjusted.
private func colorDistance(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
    let rMean = (a.0 + b.0) / 2
    let dr = a.0 - b.0
    let dg = a.1 - b.1
    let db = a.2 - b.2
    return sqrt((2 + rMean / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rMean) / 256) * db * db)
}

func closestSavedColor(to hex: String, in savedColors: [SavedColor], threshold: Double = 18) -> SavedColor? {
    let target = rgbFromHex(hex)
    return savedColors
        .map { saved in (saved, colorDistance(target, rgbFromHex(saved.hex))) }
        .filter { $0.1 <= threshold }
        .min { $0.1 < $1.1 }?
        .0
}

// MARK: - Color Harmonies

enum ColorHarmony: String, CaseIterable, Identifiable {
    case complementary = "Complementary"
    case analogous = "Analogous"
    case triadic = "Triadic"
    case splitComplementary = "Split Complementary"
    case tetradic = "Tetradic"
    case monochromatic = "Monochromatic"

    var id: String { rawValue }

    func generate(from hex: String) -> [String] {
        let hsl = hexToHSL(hex)
        switch self {
        case .complementary:
            return [hex, hslToHex((fmod(hsl.h + 180, 360), hsl.s, hsl.l))]
        case .analogous:
            return [
                hslToHex((fmod(hsl.h - 30 + 360, 360), hsl.s, hsl.l)),
                hex,
                hslToHex((fmod(hsl.h + 30, 360), hsl.s, hsl.l)),
            ]
        case .triadic:
            return [
                hex,
                hslToHex((fmod(hsl.h + 120, 360), hsl.s, hsl.l)),
                hslToHex((fmod(hsl.h + 240, 360), hsl.s, hsl.l)),
            ]
        case .splitComplementary:
            let comp = fmod(hsl.h + 180, 360)
            return [
                hex,
                hslToHex((fmod(comp - 30 + 360, 360), hsl.s, hsl.l)),
                hslToHex((fmod(comp + 30, 360), hsl.s, hsl.l)),
            ]
        case .tetradic:
            return [
                hex,
                hslToHex((fmod(hsl.h + 90, 360), hsl.s, hsl.l)),
                hslToHex((fmod(hsl.h + 180, 360), hsl.s, hsl.l)),
                hslToHex((fmod(hsl.h + 270, 360), hsl.s, hsl.l)),
            ]
        case .monochromatic:
            return [
                hslToHex((hsl.h, max(0, hsl.s - 20), min(100, hsl.l + 25))),
                hslToHex((hsl.h, hsl.s, min(100, hsl.l + 12))),
                hex,
                hslToHex((hsl.h, hsl.s, max(0, hsl.l - 12))),
                hslToHex((hsl.h, min(100, hsl.s + 10), max(0, hsl.l - 25))),
            ]
        }
    }
}

private func fmod(_ a: Double, _ b: Double) -> Double {
    let r = a.truncatingRemainder(dividingBy: b)
    return r < 0 ? r + b : r
}

private func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
    let (r, g, b) = rgbFromHex(hex)
    let rn = r / 255, gn = g / 255, bn = b / 255
    let maxV = max(rn, gn, bn)
    let minV = min(rn, gn, bn)
    let l = (maxV + minV) / 2

    if maxV == minV {
        return (0, 0, l * 100)
    }

    let d = maxV - minV
    let s = l > 0.5 ? d / (2 - maxV - minV) : d / (maxV + minV)

    let h: Double
    switch maxV {
    case rn: h = (gn - bn) / d + (gn < bn ? 6 : 0)
    case gn: h = (bn - rn) / d + 2
    default: h = (rn - gn) / d + 4
    }

    return (h * 60, s * 100, l * 100)
}

private func hslToHex(_ hsl: (h: Double, s: Double, l: Double)) -> String {
    let h = hsl.h / 360
    let s = hsl.s / 100
    let l = hsl.l / 100

    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q

    func hueToRGB(_ t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1/6 { return p + (q - p) * 6 * t }
        if t < 1/2 { return q }
        if t < 2/3 { return p + (q - p) * (2/3 - t) * 6 }
        return p
    }

    let r = hueToRGB(h + 1/3)
    let g = hueToRGB(h)
    let b = hueToRGB(h - 1/3)

    return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
}
