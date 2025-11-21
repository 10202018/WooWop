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
            ZStack(alignment: .top) {
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
                
                VStack(alignment: .leading, spacing: 0) {
                    // Search Input with cyberpunk styling at very top
                    TextField("Type song or artist", text: $query)
                        .textFieldStyle(.plain)
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.6)) // Surface card
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3), // Electric blue border
                                            lineWidth: 1
                                        )
                                )
                        )
                        .onChange(of: query) { new in
                            handleQueryChange(new)
                        }
                        .onSubmit {
                            // Just trigger suggestions display, don't call onSearch
                            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                handleQueryChange(query)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 0)

                    if isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.top, 16)
                    } else if !suggestions.isEmpty {
                    // show a scrollable list of suggestions with cyberpunk styling
                    List(suggestions, id: \.artworkURL) { item in
                        Button(action: {
                            // Always use onSelect for direct suggestion taps
                            Task {
                                if let select = onSelect {
                                    isSearching = true
                                    await select(item)
                                    isSearching = false
                                    // Let ContentView handle dismissal
                                }
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
                                            .cornerRadius(8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.4))
                                            .frame(width: 44, height: 44)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title ?? "Unknown Title")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(item.artist ?? "Unknown Artist")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.2),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    // allow the list to expand to fill remaining sheet space
                    .frame(maxHeight: .infinity)
                }
                // removed Spacer so the suggestions List can expand to fill the sheet
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Find Song")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        // Just trigger suggestions display, don't call onSearch
                        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            handleQueryChange(query)
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
