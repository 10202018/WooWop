//
//  MediaItem.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 8/13/24.
//

import Foundation

/// Represents a song or media item with metadata and artwork information.
/// 
/// This structure contains all the essential information about a song that has been
/// identified through Shazam, including artwork, title, artist, and unique identifiers.
public struct MediaItem {
  /// The URL for the song's artwork/album cover image
  let artworkURL: URL
  
  /// The title/name of the song
  let title: String?
  
  /// The artist or band name who performed the song
  let artist: String?
  
  /// Unique identifier from Shazam's database for this specific song
  let shazamID: String?
}

/// Represents a song request made by a user to a DJ.
/// 
/// This structure encapsulates all the information needed for a song request,
/// including the song details, requester information, and timestamp.
public struct SongRequest: Codable, Identifiable {
  /// Unique identifier for this specific request
  public let id = UUID()
  
  /// The title of the requested song
  let title: String
  
  /// The artist of the requested song
  let artist: String
  
  /// The name of the person making the request
  let requesterName: String
  
  /// When this request was made
  let timestamp: Date
  
  /// Optional Shazam ID for the requested song
  let shazamID: String?
  
  /// Creates a new song request with the specified details.
  /// 
  /// - Parameters:
  ///   - title: The song title
  ///   - artist: The artist name
  ///   - requesterName: Name of the person making the request
  ///   - shazamID: Optional Shazam identifier for the song
  public init(title: String, artist: String, requesterName: String, shazamID: String? = nil) {
    self.title = title
    self.artist = artist
    self.requesterName = requesterName
    self.timestamp = Date()
    self.shazamID = shazamID
  }
}
