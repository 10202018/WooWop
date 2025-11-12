import SwiftUI

/// Simple view to accept a text query and call back with the typed term.
/// This view also supports debounced autocomplete suggestions via a
/// `searchSuggestions` async closure supplied by the caller.
struct SearchInputView: View {
    @State private var query: String = ""
    @State private var isSearching: Bool = false
    @State private var suggestions: [MediaItem] = []
    @State private var suggestionTask: Task<Void, Never>? = nil

    /// Called when the user taps the Search button (final commit).
    var onSearch: (String) async -> Void

    /// Optional provider used for live suggestions while typing.
    /// Should return `[MediaItem]` for the given partial query.
    var suggestionProvider: ((String) async -> [MediaItem])? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                TextField("Type song or artist", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding([.top, .horizontal])
                    .onChange(of: query) { new in
                        handleQueryChange(new)
                    }

                if isSearching {
                    ProgressView()
                        .padding(.horizontal)
                }

                if !suggestions.isEmpty {
                    // show a compact list of suggestions
                    List(suggestions.prefix(8), id: \.artworkURL) { item in
                        Button(action: {
                            // populate the field with the suggestion and commit a search
                            query = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            Task {
                                isSearching = true
                                await onSearch(query)
                                isSearching = false
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 12) {
                                AsyncImage(url: item.artworkURL) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 44, height: 44)
                                            .clipped()
                                            .cornerRadius(4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title ?? "Unknown Title")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(item.artist ?? "Unknown Artist")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
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
        .task {
            // Optionally prefetch suggestions if query has initial value
            if let provider = suggestionProvider, !query.isEmpty {
                suggestions = await provider(query)
            }
        }
    }

    private func handleQueryChange(_ new: String) {
        // cancel previous task
        suggestionTask?.cancel()
        suggestions = []

        guard let provider = suggestionProvider, !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // debounce: wait 300ms before issuing suggestion request
        suggestionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300 * 1_000_000)
            if Task.isCancelled { return }
            let items = await provider(new)
            if Task.isCancelled { return }
            suggestions = items
        }
    }
}

#Preview {
    SearchInputView(onSearch: { _ in })
}
