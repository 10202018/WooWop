//
//  RemoteMediaItem.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 8/13/24.
//

import Foundation

/// Internal representation of media item data received from remote sources.
/// 
/// This structure serves as an intermediate data transfer object between
/// the external Shazam API responses and the app's internal MediaItem model.
/// It contains the raw data needed to construct user-facing media representations.
internal struct RemoteMediaItem {
  /// URL pointing to the song's artwork/album cover image
  internal let artworkURL: URL
  
  /// The title or name of the song
  internal let title: String
  
  /// The artist or band name who performed the song
  internal let artist: String
  
  /// Optional unique identifier from Shazam's database
  internal let shazamID: String?
}
