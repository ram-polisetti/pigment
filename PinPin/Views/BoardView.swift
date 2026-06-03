import SwiftUI
import SwiftData
import PhotosUI
import PhotosUI

struct BoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query(sort: \Pin.createdAt, order: .reverse) private var allPins: [Pin]

    @State private var selectedProject: Project?
    @State private var selectedPinID: UUID?
    @State private var showAddSheet = false
    @State private var showNewProjectSheet = false
    @State private var showRenameSheet = false
    @State private var newProjectName = ""
    @State private var renameText = ""

    // Quick-add states
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?

    private var pins: [Pin] {
        if let project = selectedProject {
            return allPins.filter { $0.project == project }
        }
        return allPins.filter { $0.project == nil }
    }

    private var title: String {
        selectedProject?.name ?? "Unfiled"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    projectPicker
                    pinContent
                }

                addButton
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    quickButtons
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPinSheet(project: selectedProject) { imageData in
                addPin(imageData: imageData)
            }
        }
        .sheet(item: $selectedPinID) { pinID in
            PinDetailView(pinID: pinID)
                .modelContext(modelContext)
        }
        .alert("New Project", isPresented: $showNewProjectSheet) {
            TextField("Project name", text: $newProjectName)
            Button("Cancel", role: .cancel) { newProjectName = "" }
            Button("Create") { createProject() }
        }
        .alert("Rename Project", isPresented: $showRenameSheet) {
            TextField("Project name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") { renameProject() }
        }
        // Quick-add handlers
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, image in
            guard let image, let data = image.jpegData(compressionQuality: 0.9) else { return }
            addPin(imageData: data)
            capturedImage = nil
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data {
                    DispatchQueue.main.async {
                        addPin(imageData: data)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result,
               let url = urls.first,
               url.startAccessingSecurityScopedResource(),
               let data = try? Data(contentsOf: url) {
                defer { url.stopAccessingSecurityScopedResource() }
                addPin(imageData: data)
            }
        }
    }

    // MARK: - Quick Add Buttons

    private var quickButtons: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.body)
            }

            Button {
                showCamera = true
            } label: {
                Image(systemName: "camera")
                    .font(.body)
            }

            Button {
                showFilePicker = true
            } label: {
                Image(systemName: "folder")
                    .font(.body)
            }
        }
    }

    // MARK: - Project Picker

    private var projectPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ProjectChip(
                    name: "Unfiled",
                    isSelected: selectedProject == nil
                ) {
                    if selectedProject == nil {
                        showRenameAlertForUnfiled()
                    } else {
                        selectedProject = nil
                    }
                }

                ForEach(projects) { project in
                    ProjectChip(
                        name: project.name,
                        isSelected: selectedProject == project
                    ) {
                        if selectedProject == project {
                            // Tap again to rename
                            renameText = project.name
                            showRenameSheet = true
                        } else {
                            selectedProject = project
                        }
                    }
                }

                Button {
                    showNewProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.thinMaterial))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func showRenameAlertForUnfiled() {
        // "Unfiled" can't be renamed; do nothing or give feedback
    }

    // MARK: - Content

    @ViewBuilder
    private var pinContent: some View {
        if pins.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pins) { pin in
                        pinRow(pin)
                            .onTapGesture {
                                // Force fault resolution
                                _ = pin.imageData
                                selectedPinID = pin.id
                            }
                    }
                }
                .padding(12)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.4))
            Text(selectedProject == nil
                 ? "Use the toolbar to add your first image"
                 : "No images in this project yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pinRow(_ pin: Pin) -> some View {
        Group {
            if let uiImage = pin.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.15))
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .bottomTrailing) {
            if !pin.inspiration.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "text.bubble.fill").font(.caption2)
                    Text("Inspiration").font(.caption2.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(8)
            }
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(.black)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                )
        }
        .padding(20)
    }

    // MARK: - Actions

    private func addPin(imageData: Data) {
        let pin = Pin(imageData: imageData, project: selectedProject)
        modelContext.insert(pin)
        try? modelContext.save()
    }

    private func createProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let project = Project(name: newProjectName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(project)
        try? modelContext.save()
        selectedProject = project
        newProjectName = ""
    }

    private func renameProject() {
        guard let project = selectedProject,
              !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        project.name = renameText.trimmingCharacters(in: .whitespaces)
        try? modelContext.save()
    }
}

// MARK: - Project Chip

struct ProjectChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? .black : Color(.systemGray5))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
