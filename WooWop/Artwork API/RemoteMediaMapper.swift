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
  /// The artwork URL is enhanced to use higher resolution when possible.
  /// 
  /// - Parameter items: Array of SHMediaItem objects from Shazam's response
  /// - Returns: Array of RemoteMediaItem objects with extracted metadata
  /// - Throws: Error if any item lacks required artwork URL or cannot be mapped
  internal static func map(_ items: [SHMediaItem]) throws -> [RemoteMediaItem] {
    return try items.map { item in
      if let originalArtworkURL = item.artworkURL {
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        let shazamID = item.shazamID
        
        // Enhance artwork resolution for better quality
        // Many artwork URLs use size tokens like 100x100 - upgrade to higher resolution only if current is low quality
        var artworkURLString = originalArtworkURL.absoluteString
        
        // DEBUG: Print original Shazam artwork URL
        print("🎵 SHAZAM DEBUG - Original artwork URL: \(artworkURLString)")
        
        if let range = artworkURLString.range(of: "\\d+x\\d+", options: .regularExpression, range: nil, locale: nil) {
          let sizeString = String(artworkURLString[range])
          
          // Extract width from the size string (e.g., "800" from "800x800")
          if let xIndex = sizeString.firstIndex(of: "x"),
             let currentWidth = Int(String(sizeString[..<xIndex])) {
            
            if currentWidth < 600 {
              print("🎵 SHAZAM DEBUG - Current resolution (\(currentWidth)x\(currentWidth)) is low, upgrading to 600x600")
              artworkURLString.replaceSubrange(range, with: "600x600")
              print("🎵 SHAZAM DEBUG - Enhanced artwork URL: \(artworkURLString)")
            } else {
              print("🎵 SHAZAM DEBUG - Current resolution (\(currentWidth)x\(currentWidth)) is already high quality, keeping original")
            }
          }
        } else {
          print("🎵 SHAZAM DEBUG - No resolution pattern found in URL - cannot enhance")
        }
        
        // Use enhanced URL if valid, otherwise fallback to original
        let enhancedArtworkURL = URL(string: artworkURLString) ?? originalArtworkURL
        
        return RemoteMediaItem(artworkURL: enhancedArtworkURL, title: title, artist: artist, shazamID: shazamID)
      } else {
        throw "Error: could not map type `SHMediaItem` to type `RemoteMediaItem`"
      }
    }
  }
  
}
