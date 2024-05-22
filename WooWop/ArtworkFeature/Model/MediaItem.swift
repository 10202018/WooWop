//
//  MediaItem.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/21/24.
//

import Foundation

@Observable class MediaItem {
  var artworkURL: URL
  
  init(artworkURL: URL) {
    self.artworkURL = artworkURL
  }
}
