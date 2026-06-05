import SwiftUI
import SwiftData

struct PinDetailView: View {
    let pinID: UUID
    let activeProject: Project?

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
    @State private var isDeleting = false
    @State private var detailImage: UIImage?
    @State private var detailImageID: UUID?
    @State private var colorSampler: ImageColorSampler?
    @AppStorage("handedness") private var handedness: String = "right"

    init(pinID: UUID, project: Project? = nil) {
        self.pinID = pinID
        self.activeProject = project
        _pins = Query(filter: #Predicate<Pin> { $0.id == pinID })
    }

    private var pin: Pin? { pins.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                imageSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                inspirationEditor
            }
            .background(AppPalette.surface)
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: handedness == "left" ? .topBarTrailing : .topBarLeading) {
                    Button("Done") { saveAndDismiss() }
                        .fontWeight(.medium)
                }
                ToolbarItem(placement: handedness == "left" ? .topBarLeading : .topBarTrailing) {
                    Button(role: .destructive) {
                        if let pin {
                            isDeleting = true
                            modelContext.delete(pin)
                            modelContext.saveAndWriteAtelierSnapshot()
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
            prepareImageIfNeeded()
            let fd = FetchDescriptor<SavedColor>()
            if let existing = try? modelContext.fetch(fd) {
                savedHexes = Set(existing.filter(isSavedColorInCurrentBoard).map(\.hex))
            }
        }
        .onChange(of: pin?.id) { _, _ in
            prepareImageIfNeeded()
        }
        .onDisappear {
            saveInspiration()
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let img = detailImage ?? pin?.uiImage

            ZStack(alignment: .bottomTrailing) {
                if let uiImage = img {
                    let imageSize = uiImage.size
                    let display = fitSize(imageSize, in: containerSize)
                    let displayOrigin = CGPoint(
                        x: (containerSize.width - display.width) / 2,
                        y: (containerSize.height - display.height) / 2
                    )
                    let displayRect = CGRect(origin: displayOrigin, size: display)

                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: display.width, height: display.height)

                        if isDropperMode {
                            Color.clear
                                .contentShape(Rectangle())
                                .frame(width: display.width, height: display.height)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let localPoint = value.location
                                            guard localPoint.x >= 0,
                                                  localPoint.x <= display.width,
                                                  localPoint.y >= 0,
                                                  localPoint.y <= display.height else { return }

                                            let clampedImagePoint = CGPoint(
                                                x: min(max(localPoint.x / display.width * imageSize.width, 0), imageSize.width - 1),
                                                y: min(max(localPoint.y / display.height * imageSize.height, 0), imageSize.height - 1)
                                            )
                                            if let color = colorSampler?.color(at: clampedImagePoint, in: imageSize, sampleRadius: 6)
                                                ?? uiImage.getPixelColor(at: clampedImagePoint, sampleRadius: 6) {
                                                pickedColor = color
                                                pickerPoint = CGPoint(
                                                    x: displayOrigin.x + localPoint.x,
                                                    y: displayOrigin.y + localPoint.y
                                                )
                                            }
                                        }
                                )
                        }
                    }
                    .frame(width: display.width, height: display.height)
                    .position(x: containerSize.width / 2, y: containerSize.height / 2)

                    if isDropperMode, let point = pickerPoint, let color = pickedColor {
                        colorSampleMarker(at: point, color: color, in: displayRect)
                            .allowsHitTesting(false)
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
                    imageOverlayControls
                        .padding(12)
                }
            }
        }
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

    private func colorSampleMarker(at point: CGPoint, color: Color, in imageRect: CGRect) -> some View {
        let target = CGPoint(
            x: min(max(point.x, imageRect.minX), imageRect.maxX),
            y: min(max(point.y, imageRect.minY), imageRect.maxY)
        )
        let previewRadius: CGFloat = 29
        let previewY: CGFloat = {
            let above = target.y - 74
            let below = target.y + 74
            if above - previewRadius >= imageRect.minY {
                return above
            }
            if below + previewRadius <= imageRect.maxY {
                return below
            }
            return min(max(above, imageRect.minY + previewRadius), imageRect.maxY - previewRadius)
        }()
        let previewX = min(max(target.x, imageRect.minX + previewRadius), imageRect.maxX - previewRadius)

        return ZStack {
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .stroke(.black.opacity(0.45), lineWidth: 1)
                }
                .position(target)

            Group {
                Rectangle()
                    .fill(.white)
                    .frame(width: 34, height: 1)
                Rectangle()
                    .fill(.white)
                    .frame(width: 1, height: 34)
            }
            .shadow(color: .black.opacity(0.45), radius: 1)
            .position(target)

            Circle()
                .fill(color)
                .frame(width: 58, height: 58)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .overlay {
                    Circle().stroke(.black.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                .position(x: previewX, y: previewY)
        }
    }

    // MARK: - Inspiration

    private var inspirationEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Add inspiration...", text: $inspirationText, axis: .vertical)
                .font(.body)
                .lineLimit(2...6)
                .padding(12)
                .foregroundStyle(AppPalette.vanDykeBrown)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppPalette.raisedSurface.opacity(0.88)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppPalette.hairline, lineWidth: 1))
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var imageOverlayControls: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if let color = pickedColor {
                pickedColorOverlay(color)
            }

            Button {
                isDropperMode.toggle()
                if !isDropperMode { pickerPoint = nil }
            } label: {
                Image(systemName: isDropperMode ? "eyedropper.halffull" : "eyedropper")
                    .font(.title3)
                    .foregroundStyle(isDropperMode ? AppPalette.titaniumWhite : AppPalette.vanDykeBrown)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(isDropperMode ? AppPalette.vanDykeBrown : AppPalette.raisedSurface)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func pickedColorOverlay(_ color: Color) -> some View {
        let hex = color.hexString()
        let named = closestNamedColor(to: hex)
        let isAlreadySaved = savedHexes.contains(hex)

        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 34, height: 34)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.8), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(named.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(hex)
                    .font(.caption2.monospaced())
                    .foregroundStyle(AppPalette.secondaryText)
            }

            Button {
                toggleSavedColor(color)
            } label: {
                Image(systemName: isAlreadySaved ? "heart.fill" : "heart")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isAlreadySaved ? AppPalette.mauve : AppPalette.rawUmber)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(AppPalette.raisedSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppPalette.hairline, lineWidth: 0.5)
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
            Text("Tap the eyedropper button on the reference, then touch and drag to pick colors")
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
        .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
    }

    private func saveColorButton(_ color: Color) -> some View {
        let hex = color.hexString()
        let isAlreadySaved = savedHexes.contains(hex)
        return Button {
            toggleSavedColor(color)
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

    private func toggleSavedColor(_ color: Color) {
        let hex = color.hexString()
        toggleSavedColor(hex: hex, name: closestNamedColor(to: hex).name)
    }

    private func toggleSavedColor(hex: String, name: String) {
        let existing = consolidatedSavedColor(hex: hex, name: name)

        if let existing, let pin, !existing.containsSourcePin(pin) {
            existing.addSourcePin(pin)
            modelContext.saveAndWriteAtelierSnapshot()
            savedHexes.insert(hex)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }

        if let existing {
            if let pin, existing.allSourcePins.count > 1 {
                existing.removeSourcePin(pin)
            } else {
                modelContext.delete(existing)
                savedHexes.remove(hex)
            }
            modelContext.saveAndWriteAtelierSnapshot()
            return
        }

        let saved = SavedColor(hex: hex, name: name, project: activeProject, sourcePin: pin)
        if let pin {
            saved.addSourcePin(pin)
        }
        modelContext.insert(saved)
        modelContext.saveAndWriteAtelierSnapshot()
        savedHexes.insert(hex)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func consolidatedSavedColor(hex: String, name: String) -> SavedColor? {
        let fd = FetchDescriptor<SavedColor>(predicate: #Predicate { $0.hex == hex })
        let exactMatches = (try? modelContext.fetch(fd)) ?? []
        var boardMatches = exactMatches.filter(isSavedColorInCurrentBoard)

        if boardMatches.isEmpty {
            let allSavedDescriptor = FetchDescriptor<SavedColor>()
            let currentBoardSaved = ((try? modelContext.fetch(allSavedDescriptor)) ?? []).filter(isSavedColorInCurrentBoard)
            if let nearMatch = closestSavedColor(to: hex, in: currentBoardSaved) {
                boardMatches = [nearMatch]
            }
        }

        guard let primary = boardMatches.first else { return nil }

        primary.name = name
        for duplicate in boardMatches.dropFirst() {
            for source in duplicate.allSourcePins {
                primary.addSourcePin(source)
            }
            modelContext.delete(duplicate)
        }

        return primary
    }

    private func isSavedColorInCurrentBoard(_ saved: SavedColor) -> Bool {
        saved.project?.id == activeProject?.id
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
                                .background(Capsule().fill(selectedHarmony == harmony ? AnyShapeStyle(color) : AnyShapeStyle(.regularMaterial)))
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
                            toggleSavedColor(hex: hexColor, name: name)
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
        .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
    }

    private func saveAndDismiss() {
        saveInspiration()
        dismiss()
    }

    private func prepareImageIfNeeded() {
        guard let pin, detailImageID != pin.id else { return }
        let image = pin.uiImage
        detailImage = image
        colorSampler = image.flatMap(ImageColorSampler.init)
        detailImageID = pin.id
    }

    private func saveInspiration() {
        guard !isDeleting else { return }
        if let pin {
            pin.inspiration = inspirationText
            modelContext.saveAndWriteAtelierSnapshot()
        }
    }
}
