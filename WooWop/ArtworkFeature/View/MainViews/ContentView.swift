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
  
  var mediaLoader: MediaLoader!
  
  @State private var mediaItem: SHMediaItem?
  @State private var rating: Int = 1
  
  @State var scale: CGFloat = 1.0
  @State var lastScaleValue: CGFloat = 1.0
  @State var scaledFrame: CGFloat = 1.0
  
  @State var showProgress: Bool = false
  
  var body: some View {
    NavigationStack {
      ZStack {
        //        GeometryReader { geo in
        if showProgress {
          ProgressView()
        } else {
          AsyncImage(url: mediaItem?.artworkURL) { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
              //              .frame(width: geo.size.width, height: geo.size.width )
                .scaleEffect(scale)
                .gesture(MagnificationGesture().onChanged { val in
                  let delta = val / self.lastScaleValue
                  self.lastScaleValue = val
                  var newScale = self.scale * delta
                  //                if newScale < 1.0 {
                  //                  newScale =  1.0
                  //                }
                  scale = newScale
                }.onEnded{ val in
                  scaledFrame = scale //Update the value once the gesture is over
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
              await getMediaItem()
            }
          } label: {
            Image(systemName: "music.note")
          }
        }
      }
    }
  }
  
  func getMediaItem() async {
      do {
        try await mediaLoader.loadMedia { result in
          switch result {
          case .match(let mediaItems):
            mediaItem = mediaItems.first
          case .noMatch:
            print ("")
          case .error(let error):
            print (error)
          }
        }
      } catch {}

    }
  }

#Preview {
  ContentView()
}
