//
//  ContentView.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI
import ShazamKit

// MARK: - Media module.

/// The main content view of the WooWop application.
/// 
/// This view serves as the primary interface for song identification and request functionality.
/// It displays song artwork, provides controls for Shazam identification, and integrates
/// with the multipeer connectivity system for sending song requests to DJs.
struct ContentView: View {
  
  /// Service responsible for loading media information from Shazam
  var mediaLoader: MediaLoader
  
  /// Manages peer-to-peer connectivity and song request functionality
  @EnvironmentObject var multipeerManager: MultipeerManager
  
  /// Currently identified media item with artwork and metadata
  @State private var mediaItem: MediaItem?
  
  /// User rating for the current song (currently unused)
  @State private var rating: Int = 1
  
  /// Controls the presentation of the song request sheet
  @State private var showingSongRequest = false
  
  /// Controls the presentation of the DJ queue management sheet
  @State private var showingDJQueue = false
  @State private var showingRecordSheet = false
  
  /// Current scale factor for the artwork image (pinch-to-zoom)
  @State var scale: CGFloat = 1.0
  
  /// Previous scale value used during gesture calculations
  @State var lastScaleValue: CGFloat = 1.0
  
  /// Final scale factor after gesture completion
  @State var scaledFrame: CGFloat = 1.0
  
  /// Indicates whether a Shazam identification is in progress
  @State var showProgress: Bool = false
  
  var body: some View {
    NavigationStack {
      ZStack {
        if showProgress {
          ProgressView()
        } else {
          AsyncImage(url: mediaItem?.artworkURL) { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(scale)
                .gesture(MagnificationGesture().onChanged { val in
                  let delta = val / self.lastScaleValue
                  self.lastScaleValue = val
                  let newScale = self.scale * delta
                  scale = newScale
                }.onEnded{ val in
                  scaledFrame = scale
                  lastScaleValue = 1
                })
            } else {
              // Show connection status when no image
              VStack(spacing: 16) {
                Image(systemName: "music.note.house")
                  .font(.system(size: 60))
                  .foregroundColor(.blue)
                
                if !multipeerManager.isDJ && !multipeerManager.isConnected {
                  VStack(spacing: 8) {
                    ProgressView()
                      .scaleEffect(1.2)
                    Text("Looking for DJ...")
                      .font(.headline)
                      .foregroundColor(.secondary)
                  }
                } else if multipeerManager.isDJ {
                  Text("DJ Mode Active")
                    .font(.headline)
                    .foregroundColor(.green)
                } else {
                  Text("Tap the music note to discover songs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                }
              }
            }
          }
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button {
            // Explicitly request the current DJ queue before opening the queue UI so listeners get an immediate snapshot
            if !multipeerManager.isDJ {
              multipeerManager.requestQueue()
            }
            showingDJQueue = true
          } label: {
            Image(systemName: "list.bullet")
          }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          if let mediaItem = mediaItem {
            Button {
              showingSongRequest = true
            } label: {
              Image(systemName: "paperplane")
            }
            Button {
              showingRecordSheet = true
            } label: {
              Image(systemName: "video")
            }
          }
          
          Button {
            Task {
              try await getMediaItem()
            }
          } label: {
            Image(systemName: "music.note")
          }
        }
      }
      .sheet(isPresented: $showingSongRequest) {
        if let mediaItem = mediaItem {
          NavigationView {
            SongRequestView(mediaItem: mediaItem, multipeerManager: multipeerManager)
          }
        }
      }
      .sheet(isPresented: $showingRecordSheet) {
        if let mediaItem = mediaItem {
          NavigationView {
            RecordVideoView(artworkURL: mediaItem.artworkURL, title: mediaItem.title)
          }
        } else {
          RecordVideoView(artworkURL: nil, title: "Record")
        }
      }
      .sheet(isPresented: $showingDJQueue) {
        DJQueueView(multipeerManager: multipeerManager)
      }
      .onAppear {
        if !multipeerManager.isDJ && !multipeerManager.isConnected {
          multipeerManager.joinSession()
        }
      }
    }
  }
  
  /// Initiates the song identification process using Shazam.
  /// 
  /// This method handles the complete identification workflow: showing progress,
  /// calling the media loader, processing results, and updating the UI state.
  /// It includes error handling for various failure scenarios.
  func getMediaItem() async throws {
    showProgress.toggle()
    do {
      let result = try await mediaLoader.loadMedia()
      switch result {
      case .match(let mediaItems):
        self.mediaItem = mediaItems.first!
      case .noMatch:
        print ("")
      case .error(let error):
        print (error)
      }
      showProgress.toggle()
    } catch(let error) {
      print(error)
      showProgress.toggle()
    }
    
  }
}

#Preview {
  ContentView(mediaLoader: RemoteMediaLoader(client: SHManagedSessionClient()))
    .environmentObject(MultipeerManager())
}
