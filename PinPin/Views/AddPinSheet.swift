import SwiftUI
import PhotosUI

struct AddPinSheet: View {
    let project: Project?
    let onImageSelected: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var capturedImage: UIImage?

    private var canUseCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                optionsList
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            loadPhotoLibraryItem(item)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, image in
            guard let image, let data = image.jpegData(compressionQuality: 0.9) else { return }
            onImageSelected(data)
            dismiss()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Add to Board")
                    .font(.title2.weight(.bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            if let project = project {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.caption2)
                    Text("Adding to \(project.name)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 8)
    }

    private var optionsList: some View {
        List {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                optionRow(icon: "photo.on.rectangle", color: .blue,
                          title: "Photo Library", subtitle: "Choose from your photos")
            }
            Button {
                showCamera = true
            } label: {
                optionRow(icon: "camera", color: .green,
                          title: canUseCamera ? "Take Photo" : "Camera Unavailable",
                          subtitle: canUseCamera ? "Use your camera" : "Use photos or files on this device")
            }
            .disabled(!canUseCamera)
            Button {
                showFilePicker = true
            } label: {
                optionRow(icon: "folder", color: .orange,
                          title: "Choose File", subtitle: "Browse your files")
            }
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
    }

    private func optionRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium)).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadPhotoLibraryItem(_ item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            if case .success(let data) = result, let data {
                DispatchQueue.main.async {
                    onImageSelected(data)
                    dismiss()
                }
            }
        }
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
            DispatchQueue.main.async {
                onImageSelected(data)
                dismiss()
            }
        }
    }
}
