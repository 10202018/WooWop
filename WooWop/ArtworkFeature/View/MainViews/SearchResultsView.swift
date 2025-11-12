import SwiftUI

/// A simple list view to display Shazam search results and allow selection or sending a request.
struct SearchResultsView: View {
    let results: [MediaItem]
    @ObservedObject var multipeerManager: MultipeerManager
    var onSelect: (MediaItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List(results, id: \ .artworkURL) { item in
                HStack(spacing: 12) {
                    AsyncImage(url: item.artworkURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 56, height: 56)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title ?? "Unknown Title")
                            .font(.headline)
                        Text(item.artist ?? "Unknown Artist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Button("Select") {
                            onSelect(item)
                        }
                        .buttonStyle(.bordered)

                        Button("Request") {
                            sendRequest(item)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!multipeerManager.isConnected)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Search Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK") { }
            }
        }
    }

    private func sendRequest(_ item: MediaItem) {
        let request = SongRequest(title: item.title ?? "Unknown Title",
                                  artist: item.artist ?? "Unknown Artist",
                                  requesterName: multipeerManager.userName,
                                  shazamID: item.shazamID)
        multipeerManager.sendSongRequest(request)
        alertMessage = "Request sent: \(request.title)"
        showingAlert = true
    }
}

#Preview {
    SearchResultsView(results: [
        MediaItem(artworkURL: URL(string: "https://example.com/1.jpg")!, title: "Song A", artist: "Artist A", shazamID: "1"),
        MediaItem(artworkURL: URL(string: "https://example.com/2.jpg")!, title: "Song B", artist: "Artist B", shazamID: "2")
    ], multipeerManager: MultipeerManager()) { _ in }
}
