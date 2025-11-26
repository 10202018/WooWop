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
  /// Controls showing the search input sheet
  @State private var showingSearchInput = false
  
  /// User rating for the current song (currently unused)
  @State private var rating: Int = 1
  
  /// Controls the presentation of the song request sheet
  @State private var showingSongRequest = false
  
  /// Controls the presentation of the DJ queue management sheet
  @State private var showingDJQueue = false
  @State private var showingRecordSheet = false
  
  /// Controls the visibility of the TikTok-style chat overlay
  @State private var showingChatOverlay = false
  
  /// Current scale factor for the artwork image (pinch-to-zoom)
  @State var scale: CGFloat = 1.0
  
  /// Previous scale value used during gesture calculations
  @State var lastScaleValue: CGFloat = 1.0
  
  /// Final scale factor after gesture completion
  @State var scaledFrame: CGFloat = 1.0
  
  /// Current offset for background image repositioning (drag-to-move)
  @State private var offset: CGSize = .zero
  
  /// Previous offset value used during gesture calculations
  @State private var lastOffset: CGSize = .zero
  
  /// Indicates whether a Shazam identification is in progress
  @State var showProgress: Bool = false
  
  /// Animation state for waveform pulsing effect
  @State private var waveformScale: CGFloat = 1.0
  @State private var waveformOpacity: Double = 1.0
  
  var body: some View {
    NavigationStack {
      ZStack {
        // Pure black background for found songs
        Color.black.ignoresSafeArea()
        
        // Background image layer - always full screen when available
        if let mediaItem = mediaItem {
          AsyncImage(url: mediaItem.artworkURL) { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                  SimultaneousGesture(
                    DragGesture()
                      .onChanged { value in
                        offset = CGSize(
                          width: lastOffset.width + value.translation.width,
                          height: lastOffset.height + value.translation.height
                        )
                      }
                      .onEnded { _ in
                        lastOffset = offset
                      },
                    MagnificationGesture()
                      .onChanged { val in
                        let delta = val / self.lastScaleValue
                        self.lastScaleValue = val
                        let newScale = self.scale * delta
                        // Constrain scale to prevent extreme zoom levels that trigger layout issues
                        scale = max(0.5, min(3.0, newScale))
                      }
                      .onEnded { val in
                        scaledFrame = scale
                        lastScaleValue = 1
                      }
                  )
                )
            }
          }
        }
        
        // Overlay content layer
        if showProgress {
          ProgressView()
        } else if mediaItem == nil {
          // Show connection status when no image
          VStack(spacing: 16) {
            Image(systemName: "waveform")
              .font(.system(size: 90))
              .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
              .shadow(color: .cyan, radius: 10)
              .scaleEffect(waveformScale)
              .opacity(waveformOpacity)
              .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                  waveformScale = 1.2
                }
                withAnimation(Animation.easeInOut(duration: 3.33).repeatForever(autoreverses: true)) {
                  waveformOpacity = 0.7
                }
              }
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
        
        // TikTok-style chat overlay (only show when connected and chat is enabled)
        if multipeerManager.isConnected && showingChatOverlay {
          TikTokChatOverlay(multipeerManager: multipeerManager)
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
              .font(.system(size: 18)) // 25% smaller (was 24)
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
          .padding(.trailing, 16) // Add extra spacing after DJ Queue icon
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(spacing: -4) { // Reduce spacing between icons
            // Chat toggle button (only show when connected)
            if multipeerManager.isConnected {
              Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                  showingChatOverlay.toggle()
                }
              } label: {
                Image(systemName: showingChatOverlay ? "message.fill" : "message")
                  .font(.system(size: 18))
                  .foregroundColor(showingChatOverlay ? .white : Color(red: 0.0, green: 0.941, blue: 1.0))
                  .padding(8)
                  .background(
                    Circle()
                      .fill(showingChatOverlay ? Color(red: 0.0, green: 0.941, blue: 1.0) : Color.black.opacity(0.4))
                  )
                  .shadow(
                    color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                    radius: 6,
                    x: 0,
                    y: 2
                  )
                  .accessibilityLabel("Toggle chat")
              }
            }
            
            if let mediaItem = mediaItem {
              Button {
                showingSongRequest = true
              } label: {
                Image(systemName: "paperplane.fill")
                  .font(.system(size: 18)) // 25% smaller (was 24)
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
                  .font(.system(size: 18)) // 25% smaller (was 24)
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
                .font(.system(size: 18)) // 25% smaller (was 24)
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
                .font(.system(size: 18)) // 25% smaller (was 24)
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
      }
      .sheet(isPresented: $showingSongRequest) {
        if let mediaItem = mediaItem {
          NavigationView {
            SongRequestView(mediaItem: mediaItem, multipeerManager: multipeerManager)
          }
          .preferredColorScheme(.dark)
        }
      }
      .sheet(isPresented: $showingSearchInput) {
        // Show a text input sheet; onSearch will call the RemoteMediaLoader.search(term:)
        SearchInputView(onSearch: { term in
          if let remote = mediaLoader as? RemoteMediaLoader {
            let result = await remote.search(term: term)
            await MainActor.run {
              // Just dismiss SearchInputView - user selects from suggestions instead
              self.showingSearchInput = false
            }
          } else {
            await MainActor.run {
              self.showingSearchInput = false
            }
          }
        }, onSelect: { item in
          // When a suggestion is tapped, directly set the media item and present the song request UI
          await MainActor.run {
            self.mediaItem = item
            self.showingSearchInput = false   // Dismiss SearchInputView
            self.showingSongRequest = true    // Go directly to SongRequestView
          }
        }, suggestionProvider: { term in
          if let remote = mediaLoader as? RemoteMediaLoader {
            let result = await remote.search(term: term)
            switch result {
            case .match(let items):
              return items
            case .noMatch:
              return []
            case .error(_):
              return []
            }
          } else {
            return []
          }
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
        // If we get multiple matches, just take the first one for direct song request
        if let firstItem = mediaItems.first {
          await MainActor.run {
            self.mediaItem = firstItem
            self.showingSongRequest = true
          }
        }
      case .noMatch:
        // Handle no match case - maybe show an alert or just do nothing
        break
      case .error(let error):
        print(error)
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
