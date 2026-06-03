import SwiftUI

struct PinCardView: View {
    let pin: Pin

    var body: some View {
        Group {
            if let uiImage = pin.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomTrailing) {
            if !pin.inspiration.isEmpty {
                Image(systemName: "text.bubble.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(6)
            }
        }
    }
}
