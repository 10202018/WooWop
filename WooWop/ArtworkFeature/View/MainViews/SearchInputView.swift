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

    /// Optional callback invoked when the user taps a suggestion directly.
    /// If provided, the suggestion tap will call this and will not call `onSearch`.
    var onSelect: ((MediaItem) async -> Void)? = nil

    /// Optional provider used for live suggestions while typing.
    /// Should return `[MediaItem]` for the given partial query.
    var suggestionProvider: ((String) async -> [MediaItem])? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // After Hours cyberpunk background for modal
                ZStack {
                    // Midnight gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.059, green: 0.047, blue: 0.161), // Deep midnight
                            Color(red: 0.102, green: 0.102, blue: 0.180)  // Dark purple-black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(.all)
                    
                    // Club light effects
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.1), // Electric pink
                            Color(red: 0.059, green: 0.047, blue: 0.161).opacity(0.3),
                            Color(red: 0.102, green: 0.102, blue: 0.180)
                        ]),
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                    .ignoresSafeArea(.all)
                    .blendMode(.overlay)
                }
                
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
                    // show a scrollable list of suggestions (no hard limit)
                    List(suggestions, id: \.artworkURL) { item in
                        Button(action: {
                            // If a direct select handler is provided, call it and avoid the SearchResults flow.
                            Task {
                                if let select = onSelect {
                                    isSearching = true
                                    await select(item)
                                    isSearching = false
                                    dismiss()
                                    return
                                }

                                // populate the field with the suggestion and commit a search
                                query = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
                    // allow the list to expand to fill remaining sheet space
                    .frame(maxHeight: .infinity)
                }
                // removed Spacer so the suggestions List can expand to fill the sheet
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
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
