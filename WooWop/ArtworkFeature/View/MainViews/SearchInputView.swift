import SwiftUI

/// Simple view to accept a text query and call back with the typed term.
struct SearchInputView: View {
    @State private var query: String = ""
    @State private var isSearching: Bool = false
    var onSearch: (String) async -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextField("Type song or artist", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                if isSearching {
                    ProgressView()
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Find Song")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        Task {
                            isSearching = true
                            await onSearch(query)
                            isSearching = false
                            dismiss()
                        }
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SearchInputView { _ in }
}
