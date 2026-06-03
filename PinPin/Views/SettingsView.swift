import SwiftUI

struct SettingsView: View {
    @AppStorage("handedness") private var handedness: String = "right"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Dominant Hand", selection: $handedness) {
                        Label("Left", systemImage: "hand.raised").tag("left")
                        Label("Right", systemImage: "hand.raised").tag("right")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 6)
                } header: {
                    Text("Handedness")
                } footer: {
                    Text("The add button moves to the side that is easiest to reach.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: handedness == "left" ? .topBarLeading : .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                }
            }
        }
    }
}
