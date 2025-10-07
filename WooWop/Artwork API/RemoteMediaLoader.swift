//
//  RemoteMediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

extension String: Error {}

/// Implementation of MediaLoader that uses remote Shazam services for song identification.
/// 
/// This class orchestrates the process of identifying songs using a ShazamClient,
/// mapping the results to internal data structures, and returning them in a format
/// suitable for the application's UI components.
public class RemoteMediaLoader: MediaLoader {
  /// The Shazam client used for audio recognition and song identification
  private var client: ShazamClient
  
  /// Initializes the loader with a specific Shazam client.
  /// 
  /// - Parameter client: The ShazamClient implementation to use for song identification
  public init(client: ShazamClient) {
    self.client = client
  }
  
  /// Asynchronously loads media information using remote Shazam services.
  /// 
  /// This method coordinates the entire identification process: capturing audio,
  /// sending it to Shazam's servers, processing the response, and converting
  /// the results to the app's internal MediaItem format.
  /// 
  /// - Returns: LoadMediaResult containing matched songs, no match, or error information
  /// - Throws: Various errors related to network issues, audio processing, or data mapping
  public func loadMedia() async throws ->  LoadMediaResult {
    // Call single method from API of ShazamClient.
    let result = await client.findMatch()
    // Use the result.
    switch result {
    case .match(let matches):
      return RemoteMediaLoader.map(matches)
    case .noMatch:
      return LoadMediaResult.noMatch
    case .error(let error):
      return LoadMediaResult.error(error)
    }
  }
  
  /// Maps Shazam API results to internal LoadMediaResult format.
  /// 
  /// This private method handles the conversion from SHMediaItem objects to
  /// the app's MediaItem format, including error handling for mapping failures.
  /// 
  /// - Parameter matches: Array of SHMediaItem objects from Shazam
  /// - Returns: LoadMediaResult with successfully mapped MediaItem objects or error
  private static func map(_ matches: [SHMediaItem]) -> LoadMediaResult {
    do {
      let mediaItems = try RemoteMediaMapper.map(matches)
      return LoadMediaResult.match(mediaItems.toModels())
    } catch(let error) {
      return LoadMediaResult.error(error)
    }
  }
}

/// Extension providing conversion from RemoteMediaItem to MediaItem.
/// 
/// This extension adds functionality to convert arrays of internal RemoteMediaItem
/// objects to user-facing MediaItem objects that can be used throughout the app.
private extension Array where Element == RemoteMediaItem {
  /// Converts RemoteMediaItem objects to MediaItem objects.
  /// 
  /// - Returns: Array of MediaItem objects suitable for UI consumption
  func toModels() -> [MediaItem] {
    return map { MediaItem(artworkURL: $0.artworkURL, title: $0.title, artist: $0.artist, shazamID: $0.shazamID) }
  }
}
