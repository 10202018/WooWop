//
//  MediaItem.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 8/13/24.
//

import Foundation

public struct MediaItem {
  let artworkURL: URL
  let title: String?
  let artist: String?
  let shazamID: String?
}

public struct SongRequest: Codable, Identifiable {
  public let id = UUID()
  let title: String
  let artist: String
  let requesterName: String
  let timestamp: Date
  let shazamID: String?
  
  public init(title: String, artist: String, requesterName: String, shazamID: String? = nil) {
    self.title = title
    self.artist = artist
    self.requesterName = requesterName
    self.timestamp = Date()
    self.shazamID = shazamID
  }
}
