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

                                if let color = uiImage.getPixelColor(at: CGPoint(x: imgX, y: imgY)) {
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
        let clampedX = min(max(point.x, 44), size.width - 44)
        let clampedY = min(max(point.y, 44), size.height - 44)

        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 48, height: 48)
            Circle()
                .stroke(.white, lineWidth: 3)
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            // Crosshair
            Group {
                Rectangle().fill(.white).frame(width: 16, height: 1)
                Rectangle().fill(.white).frame(width: 1, height: 16)
            }
        }
        .position(x: clampedX, y: clampedY - 60)
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
    func getPixelColor(at point: CGPoint) -> Color? {
        guard let cgImage = self.cgImage else { return nil }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        guard point.x >= 0, point.x < width,
              point.y >= 0, point.y < height else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * 1
        var pixel: [UInt8] = [0, 0, 0, 0]

        guard let context = CGContext(
            data: &pixel,
            width: 1, height: 1,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: -point.x, y: -point.y, width: width, height: height))

        return Color(
            red: Double(pixel[0]) / 255,
            green: Double(pixel[1]) / 255,
            blue: Double(pixel[2]) / 255
        )
    }
}
