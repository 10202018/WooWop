//
//  SongRequestView.swift
//  WooWop
//
//  Created by AI Assistant on 10/6/25.
//

import SwiftUI

struct SongRequestView: View {
    let mediaItem: MediaItem
    @ObservedObject var multipeerManager: MultipeerManager
    @State private var showingSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Song Artwork
            AsyncImage(url: mediaItem.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Song Info
            VStack(spacing: 8) {
                Text(mediaItem.title ?? "Unknown Title")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(mediaItem.artist ?? "Unknown Artist")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Connection Status
            HStack {
                Circle()
                    .fill(multipeerManager.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(multipeerManager.isConnected ? "Connected to DJ" : "Not connected to DJ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Request Button
            Button {
                sendRequest()
            } label: {
                HStack {
                    Image(systemName: "music.note")
                    Text("Request This Song")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(multipeerManager.isConnected ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!multipeerManager.isConnected)
        }
        .padding()
        .navigationTitle("Request Song")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Request Sent!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your song request has been sent to the DJ!")
        }
    }
    
    private func sendRequest() {
        let request = SongRequest(
            title: mediaItem.title ?? "Unknown Title",
            artist: mediaItem.artist ?? "Unknown Artist",
            requesterName: multipeerManager.userName,
            shazamID: mediaItem.shazamID
        )
        
        multipeerManager.sendSongRequest(request)
        showingSuccessAlert = true
    }
}

#Preview {
    NavigationView {
        SongRequestView(
            mediaItem: MediaItem(
                artworkURL: URL(string: "https://example.com/artwork.jpg")!,
                title: "Sample Song",
                artist: "Sample Artist",
                shazamID: "123456"
            ),
            multipeerManager: MultipeerManager()
        )
    }
}
