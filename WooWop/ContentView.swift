//
//  ContentView.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI
import ShazamKit

struct ContentView: View {
  
  // Set up the session
  @State private var shazamSession = SHManagedSession()
  
  @State private var mediaItem: SHMediaItem?
  @State private var rating: Int = 1
  @State private var bounceValue: Int = 0
  
  @State var scale: CGFloat = 1.0
  @State var lastScaleValue: CGFloat = 1.0
  @State var scaledFrame: CGFloat = 1.0
  
  var body: some View {
    NavigationStack {
      ZStack {
//        GeometryReader { geo in
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
          } else {
            ProgressView()
          }
        }
        
        VStack {
          Spacer()
          StarRating(rating: $rating, bounceValue: $bounceValue)
            .frame(maxWidth: .infinity, maxHeight: 100)
          //              .background(Color.blue)
            .symbolEffect(.bounce, value: 1)
        }
      }
      .toolbar {
        ToolbarItem() {
          Button {
            Task {
              mediaItem = await getSessionResult(shazamSession)
            }
          } label: {
            Image(systemName: "music.note")
          }
        }
      }
      .task {
        mediaItem = await getSessionResult(shazamSession)
      }
    }
  }
  
  func getSessionResult(_ shazamSession: SHManagedSession) async -> SHMediaItem? {
    // Use the result.
    switch await shazamSession.result() {
    case .match(let match):
      return match.mediaItems.first
    case .noMatch(_): return nil
    case .error(let error, _): return nil
    }
  }
}

#Preview {
  ContentView()
}
