//
//  ContentView.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI
import ShazamKit

// MARK: - Media module.

/// The entry view in the app.
struct ContentView: View {
  
  var mediaLoader: MediaLoader
  @EnvironmentObject var multipeerManager: MultipeerManager
  
  @State private var mediaItem: MediaItem?
  @State private var rating: Int = 1
  @State private var showingSongRequest = false
  @State private var showingDJQueue = false
  
  @State var scale: CGFloat = 1.0
  @State var lastScaleValue: CGFloat = 1.0
  @State var scaledFrame: CGFloat = 1.0
  
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
