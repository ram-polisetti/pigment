import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query(sort: \Pin.createdAt, order: .reverse) private var allPins: [Pin]

    @AppStorage("handedness") private var handedness: String = ""

    @Binding var selectedProject: Project?
    let onAddRequested: () -> Void

    @State private var selectedPinID: UUID?
    @State private var showNewProjectSheet = false
    @State private var showRenameSheet = false
    @State private var showSettings = false
    @State private var showProjectDrawer = false
    @State private var newProjectName = ""
    @State private var renameText = ""
    @GestureState private var drawerDragTranslation: CGFloat = 0

    private var isLeftHanded: Bool { handedness == "left" }
    private var drawerAlignment: Alignment { isLeftHanded ? .leading : .trailing }

    private var pins: [Pin] {
        if let project = selectedProject {
            return allPins.filter { $0.project?.id == project.id }
        }
        return allPins.filter { $0.project == nil }
    }

    private var title: String {
        selectedProject?.name ?? "Unfiled"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let drawerWidth = min(320, geometry.size.width * 0.84)

                ZStack(alignment: drawerAlignment) {
                    pinContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedProject?.id)

                    drawerEdgeHandle
                        .opacity(showProjectDrawer ? 0 : 1)
                        .allowsHitTesting(!showProjectDrawer)

                    if showProjectDrawer {
                        Color.black.opacity(0.18)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                closeProjectDrawer()
                            }
                    }

                    projectDrawer(width: drawerWidth, bottomInset: geometry.safeAreaInsets.bottom)
                        .offset(x: drawerOffset(width: drawerWidth))
                        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: showProjectDrawer)
                        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.9), value: drawerDragTranslation)
                        .gesture(drawerDragGesture(width: drawerWidth))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: isLeftHanded ? .topBarTrailing : .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                showProjectDrawer.toggle()
                            }
                        } label: {
                            Image(systemName: isLeftHanded ? "sidebar.leading" : "sidebar.trailing")
                                .font(.body)
                        }

                        if selectedProject != nil {
                            Button {
                                renameText = selectedProject?.name ?? ""
                                showRenameSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.body)
                            }
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.body)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))

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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Project Picker

    private var drawerEdgeHandle: some View {
        VStack {
            Spacer()

            Button {
                openProjectDrawer()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.caption.weight(.semibold))
                    Image(systemName: isLeftHanded ? "chevron.right" : "chevron.left")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 74)
                .background(.regularMaterial)
                .clipShape(handleShape)
                .overlay {
                    handleShape
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .gesture(edgeOpenGesture)
            .padding(isLeftHanded ? .leading : .trailing, 0)
            .padding(.bottom, 110)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: drawerAlignment)
        .ignoresSafeArea(edges: .bottom)
    }

    private var handleShape: UnevenRoundedRectangle {
        if isLeftHanded {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 12,
                topTrailingRadius: 12,
                style: .continuous
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        }
    }

    private func projectDrawer(width: CGFloat, bottomInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Projects", systemImage: "folder")
                    .font(.title3.weight(.semibold))
                    .labelStyle(.titleAndIcon)

                Spacer()

                Button {
                    showNewProjectSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 8) {
                    ProjectDrawerRow(
                        name: "Unfiled",
                        icon: "tray",
                        isSelected: selectedProject == nil
                    ) {
                        selectProject(nil)
                    }

                    ForEach(projects) { project in
                        ProjectDrawerRow(
                            name: project.name,
                            icon: "folder",
                            isSelected: selectedProject?.id == project.id
                        ) {
                            selectProject(project)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 24)
            }

        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .padding(.bottom, max(bottomInset, 12))
        .background(Color(.systemGroupedBackground))
        .clipShape(drawerShape)
        .overlay {
            drawerShape
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.16), radius: 24, x: isLeftHanded ? 8 : -8, y: 0)
    }

    private var drawerShape: UnevenRoundedRectangle {
        if isLeftHanded {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 18,
                topTrailingRadius: 18,
                style: .continuous
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var pinContent: some View {
        if pins.isEmpty {
            emptyState
                .transition(.opacity)
        } else {
            ScrollView {
                MasonryLayout(columns: 2, spacing: 10) {
                    ForEach(pins) { pin in
                        pinCard(pin)
                            .onTapGesture {
                                _ = pin.imageData
                                selectedPinID = pin.id
                            }
                    }
                }
                .padding(10)
            }
            .transition(.opacity)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Images", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Add photos, camera captures, or files to start building this board.")
        } actions: {
            Button {
                onAddRequested()
            } label: {
                Label("Add Image", systemImage: "plus.circle.fill")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pinCard(_ pin: Pin) -> some View {
        PinCardView(pin: pin)
    }

    // MARK: - Actions

    private func createProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let project = Project(name: newProjectName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(project)
        try? modelContext.save()
        selectedProject = project
        closeProjectDrawer()
        newProjectName = ""
    }

    private func renameProject() {
        guard let project = selectedProject,
              !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        project.name = renameText.trimmingCharacters(in: .whitespaces)
        try? modelContext.save()
    }

    private func selectProject(_ project: Project?) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedProject = project
            showProjectDrawer = false
        }
    }

    private func closeProjectDrawer() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            showProjectDrawer = false
        }
    }

    private func openProjectDrawer() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            showProjectDrawer = true
        }
    }

    private func drawerOffset(width: CGFloat) -> CGFloat {
        let closedOffset = isLeftHanded ? -width - 8 : width + 8
        let baseOffset = showProjectDrawer ? 0 : closedOffset
        let proposedOffset = baseOffset + drawerDragTranslation

        if isLeftHanded {
            return min(0, max(closedOffset, proposedOffset))
        }
        return max(0, min(closedOffset, proposedOffset))
    }

    private var edgeOpenGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                if isLeftHanded, value.translation.width > 36 {
                    openProjectDrawer()
                } else if !isLeftHanded, value.translation.width < -36 {
                    openProjectDrawer()
                }
            }
    }

    private func drawerDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($drawerDragTranslation) { value, state, _ in
                let translation = value.translation.width
                if showProjectDrawer {
                    state = isLeftHanded ? min(0, translation) : max(0, translation)
                } else {
                    state = isLeftHanded ? max(0, translation) : min(0, translation)
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let predicted = value.predictedEndTranslation.width

                if showProjectDrawer {
                    if isLeftHanded, translation < -width * 0.22 || predicted < -width * 0.34 {
                        closeProjectDrawer()
                    } else if !isLeftHanded, translation > width * 0.22 || predicted > width * 0.34 {
                        closeProjectDrawer()
                    }
                    return
                }

                if isLeftHanded, translation > width * 0.16 || predicted > width * 0.25 {
                    openProjectDrawer()
                } else if !isLeftHanded, translation < -width * 0.16 || predicted < -width * 0.25 {
                    openProjectDrawer()
                }
            }
    }
}

// MARK: - Project Drawer Row

struct ProjectDrawerRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(width: 24)

                Text(name)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground).opacity(0.58))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.28) : Color(.separator).opacity(0.18), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
