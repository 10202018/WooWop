//
//  MediaItem.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/21/24.
//

import Foundation

@Observable public class MediaItem: Equatable {
  var artworkURL: URL
  var shazamID: String
  
  init(artworkURL: URL, shazamID: String) {
    self.artworkURL = artworkURL
    self.shazamID = shazamID
  }
  
  public static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
    return lhs.shazamID == rhs.shazamID
  }
}
