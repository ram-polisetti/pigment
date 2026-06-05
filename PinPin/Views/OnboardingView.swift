import SwiftUI

struct OnboardingView: View {
    @AppStorage("handedness") private var handedness: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 44))
                        .foregroundStyle(AppPalette.mauve)

                    Text("Set Up PinPin")
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text("Choose your dominant hand so key actions stay easy to reach.")
                        .font(.body)
                        .foregroundStyle(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                HStack(spacing: 12) {
                    handButton(title: "Left", systemImage: "hand.raised", flipsImage: true) {
                        handedness = "left"
                    }

                    handButton(title: "Right", systemImage: "hand.raised") {
                        handedness = "right"
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
                Spacer()
            }
            .background(AppPalette.surface)
        }
    }

    private func handButton(
        title: String,
        systemImage: String,
        flipsImage: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                    .scaleEffect(x: flipsImage ? -1 : 1, y: 1)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .foregroundStyle(AppPalette.vanDykeBrown)
            .background(AppPalette.raisedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppPalette.hairline, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}
