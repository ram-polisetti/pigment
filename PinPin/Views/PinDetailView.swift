import SwiftUI
import SwiftData

struct PinDetailView: View {
    let pinID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @Query private var pins: [Pin]

    @State private var inspirationText: String = ""
    @State private var pickedColor: Color?
    @State private var selectedHarmony: ColorHarmony = .complementary
    @State private var selectedTab = 0
    @State private var isDropperMode = false
    @State private var pickerPoint: CGPoint?
    @State private var savedHexes: Set<String> = []
    @State private var didLoad = false

    init(pinID: UUID) {
        self.pinID = pinID
        _pins = Query(filter: #Predicate<Pin> { $0.id == pinID })
    }

    private var pin: Pin? { pins.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                imageSection

                Picker("View", selection: $selectedTab) {
                    Text("Inspiration").tag(0)
                    Text("Colors").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if selectedTab == 0 {
                    inspirationEditor
                } else {
                    colorsTab
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { saveAndDismiss() }
                        .fontWeight(.medium)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        if let pin {
                            modelContext.delete(pin)
                            try? modelContext.save()
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { isFocused = false }
                    }
                }
            }
        }
        .task {
            if !didLoad, let pin {
                inspirationText = pin.inspiration
                didLoad = true
            }
            let fd = FetchDescriptor<SavedColor>()
            if let existing = try? modelContext.fetch(fd) {
                savedHexes = Set(existing.map(\.hex))
            }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let img = pin?.uiImage

            ZStack(alignment: .bottomTrailing) {
                if let uiImage = img {
                    let imageSize = uiImage.size
                    let display = fitSize(imageSize, in: containerSize)

                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: display.width, height: display.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .position(x: containerSize.width / 2, y: containerSize.height / 2)

                    if isDropperMode {
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: display.width, height: display.height)
                            .position(x: containerSize.width / 2, y: containerSize.height / 2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let loc = value.location
                                        let imgX = loc.x / display.width * imageSize.width
                                        let imgY = loc.y / display.height * imageSize.height
                                        if let color = uiImage.getPixelColor(at: CGPoint(x: imgX, y: imgY)) {
                                            pickedColor = color
                                            selectedTab = 1
                                            pickerPoint = CGPoint(
                                                x: containerSize.width / 2 - display.width / 2 + loc.x,
                                                y: containerSize.height / 2 - display.height / 2 + loc.y
                                            )
                                        }
                                    }
                            )

                        if let point = pickerPoint, let color = pickedColor {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .overlay {
                                    Rectangle().fill(.white).frame(width: 12, height: 1)
                                    Rectangle().fill(.white).frame(width: 1, height: 12)
                                }
                                .shadow(radius: 3)
                                .position(x: point.x, y: point.y - 40)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            ProgressView()
                        }
                }

                if img != nil {
                    Button {
                        isDropperMode.toggle()
                        if !isDropperMode { pickerPoint = nil }
                    } label: {
                        Image(systemName: isDropperMode ? "eyedropper.halffull" : "eyedropper")
                            .font(.title3)
                            .foregroundStyle(isDropperMode ? .white : .primary)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(isDropperMode ? Color.black : Color(.systemGray5))
                            )
                    }
                    .padding(10)
                }
            }
        }
        .frame(height: 280)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func fitSize(_ imageSize: CGSize, in container: CGSize) -> CGSize {
        let ratio = imageSize.width / imageSize.height
        let containerRatio = container.width / container.height
        if ratio > containerRatio {
            let h = container.width / ratio
            return CGSize(width: container.width, height: h)
        } else {
            let w = container.height * ratio
            return CGSize(width: w, height: container.height)
        }
    }

    // MARK: - Inspiration

    private var inspirationEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $inspirationText)
                .font(.body)
                .frame(minHeight: 140)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.4), lineWidth: 1))
                .focused($isFocused)
                .padding(.horizontal, 20)

            if inspirationText.isEmpty {
                Text("Add a note about what inspired you...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
    }

    // MARK: - Colors Tab

    private var colorsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let color = pickedColor {
                    pickedColorCard(color)
                    saveColorButton(color)
                    harmoniesSection(color)
                } else {
                    noColor
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private var noColor: some View {
        VStack(spacing: 12) {
            Image(systemName: "eyedropper")
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 40)
            Text("Tap the eyedropper button on the image, then touch and drag to pick colors")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func pickedColorCard(_ color: Color) -> some View {
        let hex = color.hexString()
        let named = closestNamedColor(to: hex)
        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(named.name).font(.headline)
                HStack(spacing: 8) {
                    Text(hex).font(.subheadline.monospaced()).foregroundStyle(.secondary)
                    Button { UIPasteboard.general.string = hex } label: {
                        Image(systemName: "doc.on.doc").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }

    private func saveColorButton(_ color: Color) -> some View {
        let hex = color.hexString()
        let isAlreadySaved = savedHexes.contains(hex)
        return Button {
            if isAlreadySaved {
                let fd = FetchDescriptor<SavedColor>(predicate: #Predicate { $0.hex == hex })
                if let results = try? modelContext.fetch(fd) {
                    for saved in results { modelContext.delete(saved) }
                    try? modelContext.save()
                    savedHexes.remove(hex)
                }
            } else {
                modelContext.insert(SavedColor(hex: hex, name: closestNamedColor(to: hex).name))
                try? modelContext.save()
                savedHexes.insert(hex)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } label: {
            Label(
                isAlreadySaved ? "Saved to Favorites" : "Save to Favorites",
                systemImage: isAlreadySaved ? "heart.fill" : "heart"
            )
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(isAlreadySaved ? color.opacity(0.3) : color.opacity(0.15)))
            .foregroundStyle(color)
        }
    }

    private func harmoniesSection(_ color: Color) -> some View {
        let hex = color.hexString()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Color Harmonies").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ColorHarmony.allCases) { harmony in
                        Button {
                            selectedHarmony = harmony
                        } label: {
                            Text(harmony.rawValue)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(selectedHarmony == harmony ? color : Color(.systemGray5)))
                                .foregroundStyle(selectedHarmony == harmony ? .white : .primary)
                        }
                    }
                }
            }
            let palette = selectedHarmony.generate(from: hex)
            HStack(spacing: 0) {
                ForEach(Array(palette.enumerated()), id: \.offset) { _, hexColor in
                    let swatchColor = Color(hex: hexColor)
                    let name = closestNamedColor(to: hexColor).name
                    let isSaved = savedHexes.contains(hexColor)
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(swatchColor).frame(height: 60)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.5), lineWidth: 1))
                        Text(name).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
                        Text(hexColor).font(.system(size: 9).monospaced()).foregroundStyle(.tertiary)
                        Button {
                            if isSaved {
                                let fd = FetchDescriptor<SavedColor>(predicate: #Predicate { $0.hex == hexColor })
                                if let results = try? modelContext.fetch(fd) {
                                    for s in results { modelContext.delete(s) }
                                    try? modelContext.save()
                                    savedHexes.remove(hexColor)
                                }
                            } else {
                                modelContext.insert(SavedColor(hex: hexColor, name: name))
                                try? modelContext.save()
                                savedHexes.insert(hexColor)
                            }
                        } label: {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 10))
                                .foregroundStyle(isSaved ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }

    private func saveAndDismiss() {
        if let pin {
            pin.inspiration = inspirationText
            try? modelContext.save()
        }
        dismiss()
    }
}
