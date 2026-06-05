import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedColor.createdAt, order: .reverse) private var savedColors: [SavedColor]
    let selectedProject: Project?
    @State private var selectedSourcePinID: UUID?

    private var boardColors: [SavedColor] {
        var seenHexes = Set<String>()
        return savedColors.filter { saved in
            saved.project?.id == selectedProject?.id
        }.filter { saved in
            seenHexes.insert(saved.hex).inserted
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if boardColors.isEmpty {
                    emptyState
                } else {
                    colorList
                }
            }
            .navigationTitle("Favorites")
            .background(AppPalette.surface)
        }
        .sheet(item: $selectedSourcePinID) { pinID in
            PinDetailView(pinID: pinID, project: selectedProject)
                .modelContext(modelContext)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Saved Colors", systemImage: "heart")
        } description: {
            Text("Pick colors from references in this board and save them here.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var colorList: some View {
        List {
            ForEach(boardColors) { saved in
                HStack(spacing: 14) {
                    sourceThumbnails(for: saved)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: saved.hex))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 2)
                        )
                        .shadow(color: AppPalette.vanDykeBrown.opacity(0.1), radius: 3, y: 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(saved.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppPalette.vanDykeBrown)
                        Text(saved.hex)
                            .font(.caption.monospaced())
                            .foregroundStyle(AppPalette.secondaryText)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = saved.hex
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(AppPalette.rawUmber)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteColors)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppPalette.surface)
    }

    private func sourceThumbnails(for saved: SavedColor) -> some View {
        let sources = Array(saved.allSourcePins.prefix(3))
        let extraCount = max(0, saved.allSourcePins.count - sources.count)
        let stackWidth = 46 + CGFloat(max(0, sources.count - 1)) * 16 + (extraCount > 0 ? 20 : 0)

        return ZStack(alignment: .leading) {
            if sources.isEmpty {
                placeholderThumbnail
            } else {
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    sourceThumbnail(source)
                        .offset(x: CGFloat(index) * 16)
                        .zIndex(Double(sources.count - index))
                        .onTapGesture {
                            selectedSourcePinID = source.id
                        }
                }

                if extraCount > 0 {
                    Text("+\(extraCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppPalette.titaniumWhite)
                        .frame(width: 24, height: 24)
                        .background(AppPalette.vanDykeBrown, in: Circle())
                        .offset(x: CGFloat(sources.count) * 16 + 2, y: 13)
                        .zIndex(-1)
                }
            }
        }
        .frame(width: max(46, stackWidth), height: 46, alignment: .leading)
    }

    private func sourceThumbnail(_ pin: Pin) -> some View {
        Group {
            if let uiImage = pin.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                AppPalette.raisedSurface
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppPalette.surface, lineWidth: 2)
        }
        .shadow(color: AppPalette.vanDykeBrown.opacity(0.12), radius: 3, y: 1)
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(AppPalette.raisedSurface)
            .frame(width: 46, height: 46)
            .overlay {
                Image(systemName: "photo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.rawUmber)
            }
    }

    private func deleteColors(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(boardColors[index])
        }
        try? modelContext.save()
    }
}
