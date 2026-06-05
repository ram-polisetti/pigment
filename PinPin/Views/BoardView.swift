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
    @State private var showDeleteProjectAlert = false
    @State private var showDeleteReferenceAlert = false
    @State private var showSettings = false
    @State private var showProjectDrawer = false
    @State private var newProjectName = ""
    @State private var renameText = ""
    @State private var projectPendingDeletion: Project?
    @State private var pinPendingDeletion: Pin?
    @State private var recentlyDeletedProject: DeletedProjectSnapshot?
    @GestureState private var drawerDragTranslation: CGFloat = 0

    private var isLeftHanded: Bool { handedness == "left" }
    private var drawerAlignment: Alignment { isLeftHanded ? .leading : .trailing }

    private var pins: [Pin] {
        allPins.filter { $0.isInProject(selectedProject) }
    }

    private var title: String {
        selectedProject?.name ?? "Unfiled"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let drawerWidth = min(272, geometry.size.width * 0.72)
                let bottomNavigationClearance: CGFloat = 118
                let topMenuClearance: CGFloat = 104
                let drawerBottomPadding = max(geometry.safeAreaInsets.bottom, bottomNavigationClearance)
                let drawerAvailableHeight = max(220, geometry.size.height - topMenuClearance - drawerBottomPadding)
                let drawerMaxHeight = min(360, drawerAvailableHeight)

                ZStack(alignment: isLeftHanded ? .bottomLeading : .bottomTrailing) {
                    pinContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedProject?.id)
                        .simultaneousGesture(boardSwipeGesture)

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

                    projectDrawer(width: drawerWidth, maxHeight: drawerMaxHeight)
                        .padding(.bottom, drawerBottomPadding)
                        .offset(x: drawerOffset(width: drawerWidth))
                        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: showProjectDrawer)
                        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.9), value: drawerDragTranslation)
                        .gesture(drawerDragGesture(width: drawerWidth))

                    if let recentlyDeletedProject {
                        undoDeleteBanner(recentlyDeletedProject)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 116)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: isLeftHanded ? .topBarTrailing : .topBarLeading) {
                    HStack(spacing: 16) {
                        if selectedProject != nil {
                            Button {
                                renameText = selectedProject?.name ?? ""
                                showRenameSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.body)
                            }
                            Button(role: .destructive) {
                                projectPendingDeletion = selectedProject
                                showDeleteProjectAlert = true
                            } label: {
                                Image(systemName: "trash")
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
            .background(AppPalette.surface)

        }
        .sheet(item: $selectedPinID) { pinID in
            PinDetailView(pinID: pinID, project: selectedProject)
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
        .alert("Delete Project?", isPresented: $showDeleteProjectAlert, presenting: projectPendingDeletion) { project in
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                deleteProject(project)
            }
        } message: { project in
            Text("This will delete \(project.name). Shared references stay in their other projects.")
        }
        .alert("Delete Reference?", isPresented: $showDeleteReferenceAlert, presenting: pinPendingDeletion) { pin in
            Button("Cancel", role: .cancel) {
                pinPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                deleteReference(pin)
            }
        } message: { _ in
            Text(selectedProject == nil ? "This deletes this reference." : "This removes this reference from this project.")
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
                .foregroundStyle(AppPalette.rawUmber)
                .frame(width: 34, height: 74)
                .background(AppPalette.raisedSurface)
                .clipShape(handleShape)
                .overlay {
                    handleShape
                        .stroke(AppPalette.hairline, lineWidth: 0.5)
                }
                .shadow(color: AppPalette.vanDykeBrown.opacity(0.1), radius: 8, y: 2)
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

    private func projectDrawer(width: CGFloat, maxHeight: CGFloat) -> some View {
        let rowAreaMaxHeight = max(132, maxHeight - 74)

        return ViewThatFits(in: .vertical) {
            projectDrawerBody(width: width, rowAreaMaxHeight: rowAreaMaxHeight, isScrollable: false)
            projectDrawerBody(width: width, rowAreaMaxHeight: rowAreaMaxHeight, isScrollable: true)
        }
        .frame(width: width)
        .frame(maxHeight: maxHeight, alignment: .bottom)
    }

    private func projectDrawerBody(width: CGFloat, rowAreaMaxHeight: CGFloat, isScrollable: Bool) -> some View {
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
            .foregroundStyle(AppPalette.vanDykeBrown)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 10)

            if isScrollable {
                ScrollView {
                    projectRows
                }
                .frame(maxHeight: rowAreaMaxHeight)
                .scrollIndicators(.visible)
            } else {
                projectRows
            }

            Divider()
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
        }
        .frame(width: width)
        .background(AppPalette.raisedSurface)
        .clipShape(drawerShape)
        .overlay {
            drawerShape
                .stroke(AppPalette.hairline, lineWidth: 0.5)
        }
        .shadow(color: AppPalette.vanDykeBrown.opacity(0.2), radius: 24, x: isLeftHanded ? 8 : -8, y: 0)
    }

    private func undoDeleteBanner(_ snapshot: DeletedProjectSnapshot) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.rawUmber)

            Text("Deleted \(snapshot.name)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppPalette.vanDykeBrown)
                .lineLimit(1)

            Spacer()

            Button("Undo") {
                restoreProject(snapshot)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.mauve)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppPalette.raisedSurface, in: Capsule())
        .overlay {
            Capsule()
                .stroke(AppPalette.hairline, lineWidth: 0.5)
        }
        .shadow(color: AppPalette.vanDykeBrown.opacity(0.16), radius: 16, y: 5)
    }

    private var projectRows: some View {
        VStack(spacing: 8) {
            ProjectDrawerRow(
                name: "Unfiled",
                icon: "tray",
                referenceCount: referenceCount(for: nil),
                isSelected: selectedProject == nil
            ) {
                selectProject(nil)
            }

            ForEach(projects) { project in
                ProjectDrawerRow(
                    name: project.name,
                    icon: "folder",
                    referenceCount: referenceCount(for: project),
                    isSelected: selectedProject?.id == project.id
                ) {
                    selectProject(project)
                }
                .swipeActions(edge: isLeftHanded ? .leading : .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        projectPendingDeletion = project
                        showDeleteProjectAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
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
            GeometryReader { geometry in
                let columns = masonryColumnCount(for: geometry.size.width)
                let horizontalPadding = masonryHorizontalPadding(for: geometry.size.width)

                ScrollView {
                    MasonryLayout(columns: columns, spacing: 12) {
                        ForEach(pins) { pin in
                            pinCard(pin)
                                .onTapGesture {
                                    _ = pin.storedImageData
                                    selectedPinID = pin.id
                                }
                                .contextMenu {
                                    projectLinkMenu(for: pin)

                                    if selectedProject != nil, pin.projects.count > 1 {
                                        Button {
                                            removeReferenceFromCurrentProject(pin)
                                        } label: {
                                            Label("Remove from This Project", systemImage: "minus.circle")
                                        }
                                    }

                                    Button(role: .destructive) {
                                        pinPendingDeletion = pin
                                        showDeleteReferenceAlert = true
                                    } label: {
                                        Label("Delete Reference", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .transition(.opacity)
        }
    }

    private func masonryColumnCount(for width: CGFloat) -> Int {
        switch width {
        case 900...:
            return 4
        case 620..<900:
            return 3
        default:
            return 2
        }
    }

    private func masonryHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 900...:
            return 24
        case 620..<900:
            return 18
        default:
            return 10
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No References", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Add photos, camera captures, or files to start building this board.")
        } actions: {
            Button {
                onAddRequested()
            } label: {
                Label("Add Reference", systemImage: "plus.circle.fill")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pinCard(_ pin: Pin) -> some View {
        PinCardView(pin: pin)
    }

    @ViewBuilder
    private func projectLinkMenu(for pin: Pin) -> some View {
        let availableProjects = projects.filter { project in
            !pin.projects.contains { $0.id == project.id }
        }

        if !availableProjects.isEmpty {
            Menu {
                ForEach(availableProjects) { project in
                    Button {
                        addReference(pin, to: project)
                    } label: {
                        Label(project.name, systemImage: "folder.badge.plus")
                    }
                }
            } label: {
                Label("Add to Project", systemImage: "folder.badge.plus")
            }
        }
    }

    // MARK: - Actions

    private func createProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let project = Project(name: newProjectName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(project)
        modelContext.saveAndWriteAtelierSnapshot()
        selectedProject = project
        closeProjectDrawer()
        newProjectName = ""
    }

    private func renameProject() {
        guard let project = selectedProject,
              !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        project.name = renameText.trimmingCharacters(in: .whitespaces)
        modelContext.saveAndWriteAtelierSnapshot()
    }

    private func deleteProject(_ project: Project) {
        let snapshot = DeletedProjectSnapshot(
            name: project.name,
            references: allPins
                .filter { $0.isInProject(project) }
                .map { DeletedReferenceSnapshot(pinID: $0.id, imageData: $0.storedImageData, inspiration: $0.inspiration) }
        )
        let replacementProject = replacementProjectAfterDeleting(project)
        if selectedProject?.id == project.id {
            selectedProject = replacementProject
        }
        projectPendingDeletion = nil
        closeProjectDrawer()
        modelContext.delete(project)
        modelContext.saveAndWriteAtelierSnapshot()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            recentlyDeletedProject = snapshot
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if recentlyDeletedProject?.id == snapshot.id {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    recentlyDeletedProject = nil
                }
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func restoreProject(_ snapshot: DeletedProjectSnapshot) {
        let project = Project(name: snapshot.name)
        modelContext.insert(project)
        for reference in snapshot.references {
            if let existingPin = allPins.first(where: { $0.id == reference.pinID }) {
                existingPin.addToProject(project)
            } else {
                modelContext.insert(Pin(imageData: reference.imageData, inspiration: reference.inspiration, project: project))
            }
        }
        modelContext.saveAndWriteAtelierSnapshot()
        selectedProject = project
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            recentlyDeletedProject = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func replacementProjectAfterDeleting(_ project: Project) -> Project? {
        guard let deletedIndex = projects.firstIndex(where: { $0.id == project.id }) else {
            return nil
        }

        let nextIndex = projects.index(after: deletedIndex)
        if nextIndex < projects.endIndex {
            return projects[nextIndex]
        }

        let previousIndex = projects.index(before: deletedIndex)
        if projects.indices.contains(previousIndex) {
            return projects[previousIndex]
        }

        return nil
    }

    private func deleteReference(_ pin: Pin) {
        pinPendingDeletion = nil
        if selectedPinID == pin.id {
            selectedPinID = nil
        }
        if let selectedProject, pin.projects.count > 1 {
            pin.removeFromProject(selectedProject)
        } else {
            modelContext.delete(pin)
        }
        modelContext.saveAndWriteAtelierSnapshot()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func addReference(_ pin: Pin, to project: Project) {
        pin.addToProject(project)
        modelContext.saveAndWriteAtelierSnapshot()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func removeReferenceFromCurrentProject(_ pin: Pin) {
        guard let selectedProject else { return }
        pin.removeFromProject(selectedProject)
        modelContext.saveAndWriteAtelierSnapshot()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func referenceCount(for project: Project?) -> Int {
        if let project {
            return allPins.filter { $0.isInProject(project) }.count
        }
        return allPins.filter { $0.isInProject(nil) }.count
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

    private var boardSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 36)
            .onEnded { value in
                guard !showProjectDrawer else { return }
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > 56, abs(horizontal) > abs(vertical) * 1.35 else { return }

                if horizontal < 0 {
                    moveToAdjacentProject(step: 1)
                } else {
                    moveToAdjacentProject(step: -1)
                }
            }
    }

    private func moveToAdjacentProject(step: Int) {
        let projectIDs = projects.map(\.id)
        let currentIndex: Int

        if let selectedID = selectedProject?.id,
           let projectIndex = projectIDs.firstIndex(of: selectedID) {
            currentIndex = projectIndex + 1
        } else {
            currentIndex = 0
        }

        let boardCount = projects.count + 1
        guard boardCount > 1 else { return }

        let nextIndex = (currentIndex + step + boardCount) % boardCount
        let nextProject = nextIndex == 0 ? nil : projects[nextIndex - 1]

        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedProject = nextProject
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    let referenceCount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? AppPalette.vanDykeBrown : AppPalette.rawUmber)
                    .frame(width: 24)

                Text(name)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(AppPalette.vanDykeBrown)
                    .lineLimit(1)

                Spacer()

                Text("\(referenceCount)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? AppPalette.vanDykeBrown : AppPalette.rawUmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppPalette.titaniumWhite.opacity(isSelected ? 0.62 : 0.48), in: Capsule())

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.mauve)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppPalette.selectedSurface)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppPalette.surface.opacity(0.72))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppPalette.mauve.opacity(0.38) : AppPalette.hairline, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DeletedProjectSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let references: [DeletedReferenceSnapshot]
}

private struct DeletedReferenceSnapshot {
    let pinID: UUID
    let imageData: Data
    let inspiration: String
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
