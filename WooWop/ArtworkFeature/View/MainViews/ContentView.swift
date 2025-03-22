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
  
  @State private var mediaItem: MediaItem?
  @State private var rating: Int = 1
  
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
            }
          }
        }
      }
      .toolbar {
        ToolbarItem() {
          Button {
            Task {
              try await getMediaItem()
            }
          } label: {
            Image(systemName: "music.note")
          }
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
}
