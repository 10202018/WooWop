//
//  RemoteMediaMapper.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 8/13/24.
//

import Foundation
import ShazamKit

/// Utility class for converting Shazam API responses to internal data structures.
/// 
/// This mapper handles the transformation of SHMediaItem objects (from ShazamKit)
/// into the app's internal RemoteMediaItem representation, extracting and formatting
/// the necessary metadata while handling potential missing or invalid data.
internal final class RemoteMediaMapper {
  /// Placeholder array for items (currently unused)
  let items = [RemoteMediaItem]()
  
  /// Converts an array of Shazam media items to internal RemoteMediaItem objects.
  /// 
  /// This method extracts artwork URLs, titles, artists, and Shazam IDs from the
  /// Shazam API response, providing fallback values for missing information.
  /// 
  /// - Parameter items: Array of SHMediaItem objects from Shazam's response
  /// - Returns: Array of RemoteMediaItem objects with extracted metadata
  /// - Throws: Error if any item lacks required artwork URL or cannot be mapped
  internal static func map(_ items: [SHMediaItem]) throws -> [RemoteMediaItem] {
    return try items.map { item in
      if let artworkURL = item.artworkURL {
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        let shazamID = item.shazamID
        return RemoteMediaItem(artworkURL: artworkURL, title: title, artist: artist, shazamID: shazamID)
      } else {
        throw "Error: could not map type `SHMediaItem` to type `RemoteMediaItem`"
      }
    }
  }
  
}
