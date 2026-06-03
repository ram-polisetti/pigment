import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedColor.createdAt, order: .reverse) private var savedColors: [SavedColor]

    var body: some View {
        NavigationStack {
            Group {
                if savedColors.isEmpty {
                    emptyState
                } else {
                    colorList
                }
            }
            .navigationTitle("Favorites")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No saved colors yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Pick colors from your images and save them here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var colorList: some View {
        List {
            ForEach(savedColors) { saved in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: saved.hex))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(saved.name)
                            .font(.body.weight(.medium))
                        Text(saved.hex)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = saved.hex
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteColors)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteColors(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedColors[index])
        }
        try? modelContext.save()
    }
}
