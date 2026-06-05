import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("handedness") private var handedness: String = ""
    @Environment(\.modelContext) private var modelContext

    @State private var showOnboarding = false
    @State private var selectedTab = 0
    @State private var selectedProject: Project?
    @State private var showAddMenu = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var capturedImage: UIImage?
    @State private var photoData: Data?

    private var canUseCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    private var isLeftHanded: Bool { handedness == "left" }
    private var controlSurface: Color { AppPalette.raisedSurface }
    private var selectedControlSurface: Color { AppPalette.selectedSurface }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if selectedTab == 0 {
                    BoardView(selectedProject: $selectedProject) {
                        showAddMenu = true
                    }
                } else {
                    FavoritesView(selectedProject: selectedProject)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 106)
            }

            if showAddMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            showAddMenu = false
                        }
                    }
            }

            bottomControls
        }
        .fontDesign(.rounded)
        .background(AppPalette.surface)
        .onAppear {
            if handedness.isEmpty { showOnboarding = true }
        }
        .onChange(of: handedness) { _, newValue in
            if !newValue.isEmpty { showOnboarding = false }
        }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, image in
            guard let image, let data = image.normalizedJPEGData(compressionQuality: 0.9) else { return }
            addPin(imageData: data)
            capturedImage = nil
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker(imageData: $photoData)
                .ignoresSafeArea()
        }
        .onChange(of: photoData) { _, data in
            guard let data else { return }
            addPin(imageData: data)
            photoData = nil
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            handleFileImport(result)
        }
    }

    private var bottomControls: some View {
        VStack(alignment: isLeftHanded ? .leading : .trailing, spacing: 12) {
            if showAddMenu {
                addPillMenu
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.96)))
            }

            HStack(spacing: 14) {
                if isLeftHanded {
                    addButton
                }

                navCluster

                if !isLeftHanded {
                    addButton
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.bottom, 12)
    }

    private var navCluster: some View {
        HStack(spacing: 4) {
            tabButton(title: "Board", systemImage: "square.grid.2x2", tab: 0)
            tabButton(title: "Colors", systemImage: "heart", tab: 2)
        }
        .padding(5)
        .background(controlSurface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppPalette.hairline, lineWidth: 0.5)
        }
        .shadow(color: AppPalette.vanDykeBrown.opacity(0.14), radius: 18, y: 5)
    }

    private func tabButton(title: String, systemImage: String, tab: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                selectedTab = tab
                showAddMenu = false
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.body.weight(selectedTab == tab ? .semibold : .medium))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(selectedTab == tab ? AppPalette.vanDykeBrown : AppPalette.rawUmber)
                .frame(minWidth: 106)
                .frame(height: 52)
                .background {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 21, style: .continuous)
                            .fill(selectedControlSurface)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                showAddMenu.toggle()
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppPalette.vanDykeBrown)
                .frame(width: 62, height: 62)
                .background(controlSurface)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AppPalette.hairline, lineWidth: 0.5)
                }
                .rotationEffect(.degrees(showAddMenu ? 45 : 0))
                .shadow(color: AppPalette.vanDykeBrown.opacity(0.16), radius: 18, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var addPillMenu: some View {
        HStack(spacing: 12) {
            addPill(systemImage: "photo.on.rectangle") {
                showPhotoPicker = true
            }

            addPill(systemImage: "camera", isDisabled: !canUseCamera) {
                showCamera = true
            }

            addPill(systemImage: "folder") {
                showFilePicker = true
            }
        }
        .padding(7)
        .background(controlSurface)
        .clipShape(Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppPalette.hairline, lineWidth: 0.5)
        }
        .shadow(color: AppPalette.vanDykeBrown.opacity(0.16), radius: 18, y: 5)
        .padding(.horizontal, 18)
    }

    private func addPill(systemImage: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                showAddMenu = false
            }
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(isDisabled ? AppPalette.rawUmber.opacity(0.35) : AppPalette.vanDykeBrown)
                .frame(width: 58, height: 46)
                .background(selectedControlSurface)
                .clipShape(Capsule(style: .continuous))
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }

    private func addPin(imageData: Data) {
        let normalizedData = UIImage(data: imageData)?.normalizedJPEGData(compressionQuality: 0.9) ?? imageData
        let pin = Pin(imageData: normalizedData, project: selectedProject)
        modelContext.insert(pin)
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result,
           let url = urls.first {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            guard let data = try? Data(contentsOf: url) else { return }
            addPin(imageData: data)
        }
    }
}
