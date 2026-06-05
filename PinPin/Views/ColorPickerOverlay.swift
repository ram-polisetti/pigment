import SwiftUI

struct ColorPickerOverlay: View {
    let uiImage: UIImage
    let onColorPicked: (Color) -> Void

    @State private var touchPoint: CGPoint?
    @State private var pickedColor: Color = .clear
    @State private var showMagnifier = false

    var body: some View {
        GeometryReader { geometry in
            let imageSize = uiImage.size
            let displaySize = AVMakeRect(aspectRatio: imageSize, insideRect: geometry.frame(in: .local)).size
            let displayOrigin = CGPoint(
                x: (geometry.size.width - displaySize.width) / 2,
                y: (geometry.size.height - displaySize.height) / 2
            )

            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                // Only process if within the image bounds
                                guard point.x >= displayOrigin.x,
                                      point.x <= displayOrigin.x + displaySize.width,
                                      point.y >= displayOrigin.y,
                                      point.y <= displayOrigin.y + displaySize.height
                                else { return }

                                touchPoint = point
                                showMagnifier = true

                                // Convert to image coordinates
                                let imgX = (point.x - displayOrigin.x) / displaySize.width * imageSize.width
                                let imgY = (point.y - displayOrigin.y) / displaySize.height * imageSize.height

                                if let color = uiImage.getPixelColor(at: CGPoint(x: imgX, y: imgY), sampleRadius: 6) {
                                    pickedColor = color
                                    onColorPicked(color)
                                }
                            }
                            .onEnded { _ in
                                showMagnifier = false
                            }
                    )

                // Magnifier circle
                if showMagnifier, let point = touchPoint {
                    magnifier(at: point, color: pickedColor, in: geometry.size)
                }
            }
        }
    }

    private func magnifier(at point: CGPoint, color: Color, in size: CGSize) -> some View {
        let clampedX = min(max(point.x, 54), size.width - 54)
        let clampedY = min(max(point.y, 54), size.height - 54)

        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 64, height: 64)
            Circle()
                .stroke(.white, lineWidth: 3)
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            // Crosshair
            Group {
                Rectangle().fill(.white).frame(width: 22, height: 1)
                Rectangle().fill(.white).frame(width: 1, height: 22)
            }
        }
        .position(x: clampedX, y: clampedY - 72)
    }
}

// Helper to get aspect-fit rect
private func AVMakeRect(aspectRatio: CGSize, insideRect boundingRect: CGRect) -> CGRect {
    let ratio = aspectRatio.width / aspectRatio.height
    let boundingRatio = boundingRect.width / boundingRect.height

    if ratio > boundingRatio {
        let height = boundingRect.width / ratio
        let y = boundingRect.midY - height / 2
        return CGRect(x: boundingRect.minX, y: y, width: boundingRect.width, height: height)
    } else {
        let width = boundingRect.height * ratio
        let x = boundingRect.midX - width / 2
        return CGRect(x: x, y: boundingRect.minY, width: width, height: boundingRect.height)
    }
}

// MARK: - UIImage Pixel Sampling

extension UIImage {
    func getPixelColor(at point: CGPoint, sampleRadius: CGFloat = 6) -> Color? {
        ImageColorSampler(image: self)?.color(at: point, in: size, sampleRadius: sampleRadius)
    }
}

final class ImageColorSampler {
    private let width: Int
    private let height: Int
    private let bytesPerPixel = 4
    private let bytesPerRow: Int
    private let pixels: [UInt8]

    init?(image: UIImage) {
        guard let cgImage = image.cgImage else { return nil }

        width = cgImage.width
        height = cgImage.height
        bytesPerRow = width * bytesPerPixel
        var pixelBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixelBuffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        pixels = pixelBuffer
    }

    func color(at point: CGPoint, in imageSize: CGSize, sampleRadius: CGFloat = 6) -> Color? {
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let pixelX = Int((point.x / imageSize.width * CGFloat(width)).rounded())
        let pixelY = Int((point.y / imageSize.height * CGFloat(height)).rounded())
        guard pixelX >= 0, pixelX < width, pixelY >= 0, pixelY < height else { return nil }

        let radius = max(0, Int(sampleRadius.rounded()))
        let minX = max(0, pixelX - radius)
        let maxX = min(width - 1, pixelX + radius)
        let minY = max(0, pixelY - radius)
        let maxY = min(height - 1, pixelY + radius)

        var red = 0
        var green = 0
        var blue = 0
        var count = 0

        for y in minY...maxY {
            let rowStart = y * bytesPerRow
            for x in minX...maxX {
                let offset = rowStart + x * bytesPerPixel
                red += Int(pixels[offset])
                green += Int(pixels[offset + 1])
                blue += Int(pixels[offset + 2])
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return Color(
            red: Double(red) / Double(count) / 255,
            green: Double(green) / Double(count) / 255,
            blue: Double(blue) / Double(count) / 255
        )
    }
}
