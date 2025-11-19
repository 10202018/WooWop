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
  /// The list of search results returned from Shazam
  @State private var searchResults: [MediaItem] = []
  /// Controls showing the search results sheet
  @State private var showingSearchResults = false
  /// Controls showing the search input sheet
  @State private var showingSearchInput = false
  
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
        // Black background for the entire app
        Color.black.ignoresSafeArea(.all)
        
        if showProgress {
          ProgressView()
        } else {
          AsyncImage(url: mediaItem?.artworkURL) { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
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
                  .font(.system(size: 90))
                  .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                
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
            Image(systemName: "list.bullet.rectangle.fill")
              .font(.system(size: 24))
              .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
              .padding(8)
              .background(
                Circle()
                  .fill(Color.black.opacity(0.4))
              )
              .shadow(
                color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                radius: 6,
                x: 0,
                y: 2
              )
              .accessibilityLabel("Queue")
          }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          if let mediaItem = mediaItem {
            Button {
              showingSongRequest = true
            } label: {
              Image(systemName: "paperplane.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                .padding(8)
                .background(
                  Circle()
                    .fill(Color.black.opacity(0.4))
                )
                .shadow(
                  color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                  radius: 6,
                  x: 0,
                  y: 2
                )
                .accessibilityLabel("Send request")
            }
            Button {
              showingRecordSheet = true
            } label: {
              Image(systemName: "video.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                .padding(8)
                .background(
                  Circle()
                    .fill(Color.black.opacity(0.4))
                )
                .shadow(
                  color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                  radius: 6,
                  x: 0,
                  y: 2
                )
                .accessibilityLabel("Record video")
            }
          }

          // Existing quick-identify button (unchanged behavior)
          Button {
            Task {
              try await getMediaItem()
            }
          } label: {
            Image(systemName: "music.note")
              .font(.system(size: 24))
              .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
              .padding(8)
              .background(
                Circle()
                  .fill(Color.black.opacity(0.4))
              )
              .shadow(
                color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                radius: 6,
                x: 0,
                y: 2
              )
              .accessibilityLabel("Identify")
          }

          // New dedicated "Find" button that presents a text search input
          Button {
            showingSearchInput = true
          } label: {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 24))
              .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
              .padding(8)
              .background(
                Circle()
                  .fill(Color.black.opacity(0.4))
              )
              .shadow(
                color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                radius: 6,
                x: 0,
                y: 2
              )
              .accessibilityLabel("Find song")
          }
        }
      }
      .sheet(isPresented: $showingSongRequest) {
        if let mediaItem = mediaItem {
          NavigationView {
            SongRequestView(mediaItem: mediaItem, multipeerManager: multipeerManager)
          }
          .preferredColorScheme(.dark)
        }
      }
      .sheet(isPresented: $showingSearchResults) {
        SearchResultsView(results: searchResults, multipeerManager: multipeerManager) { selected in
          // When the user selects an item from search results, set it as current mediaItem
          self.mediaItem = selected
          self.showingSearchResults = false
          self.showingSongRequest = true
        }
        .preferredColorScheme(ColorScheme.dark)
      }
      .sheet(isPresented: $showingSearchInput) {
        // Show a text input sheet; onSearch will call the RemoteMediaLoader.search(term:)
        SearchInputView(onSearch: { term in
          if let remote = mediaLoader as? RemoteMediaLoader {
            let result = await remote.search(term: term)
            switch result {
            case .match(let items):
              self.searchResults = items
              self.showingSearchResults = true
            case .noMatch:
              self.searchResults = []
              self.showingSearchResults = true
            case .error(let error):
              print("Search error: \(error)")
              self.searchResults = []
              self.showingSearchResults = true
            }
          } else {
            // mediaLoader doesn't support text search; no-op
            self.searchResults = []
            self.showingSearchResults = true
          }
        }, onSelect: { item in
          // When a suggestion is tapped, directly set the media item and present the song request UI
          await MainActor.run {
            self.mediaItem = item
            self.showingSearchResults = false
            self.showingSongRequest = true
          }
        }, suggestionProvider: { term in
          // Provide live suggestions by reusing the RemoteMediaLoader.text search fallback
          if let remote = mediaLoader as? RemoteMediaLoader {
            let result = await remote.search(term: term)
            switch result {
            case .match(let items): return items
            default: return []
            }
          }
          return []
        })
        .preferredColorScheme(ColorScheme.dark)
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
      .preferredColorScheme(ColorScheme.dark)
      .sheet(isPresented: $showingDJQueue) {
        DJQueueView(multipeerManager: multipeerManager)
          .preferredColorScheme(ColorScheme.dark)
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

  /// Loads media items from the media loader and presents the results for user selection.
  func getMediaItems() async throws {
    showProgress.toggle()
    do {
      let result = try await mediaLoader.loadMedia()
      switch result {
      case .match(let mediaItems):
        // Present the list of matches so the user may choose which to request
        self.searchResults = mediaItems
        self.showingSearchResults = true
      case .noMatch:
        self.searchResults = []
      case .error(let error):
        print(error)
        self.searchResults = []
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
