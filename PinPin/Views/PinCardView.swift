import SwiftUI

struct PinCardView: View {
    let pin: Pin

    var body: some View {
        Group {
            if let uiImage = pin.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(uiImage.size.width / max(uiImage.size.height, 1), contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .overlay(alignment: .bottomTrailing) {
            if !pin.inspiration.isEmpty {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(8)
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
