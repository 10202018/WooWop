//
//  RemoteMediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

extension String: Error {}

public class RemoteMediaLoader: MediaLoader {
  private var client: ShazamClient
  
  public init(client: ShazamClient) {
    self.client = client
  }
  
  public func loadMedia() async throws ->  LoadMediaResult {
    // Call single method from API of ShazamClient.
    let result = await client.findMatch()
    // Use the result.
    switch result {
    case .match(let matches):
      do {
        let mediaItems = try RemoteMediaMapper.map(matches)
        return LoadMediaResult.match(mediaItems.toModels())
      } catch(let error) {
        return LoadMediaResult.error(error)
      }
    case .noMatch:
      return LoadMediaResult.noMatch
    case .error(let error):
      return LoadMediaResult.error(error)
    }
  }
}

internal final class RemoteMediaMapper {
  let items = [RemoteMediaItem]()
  
  internal static func map(_ items: [SHMediaItem]) throws -> [RemoteMediaItem] {
    return try items.map { item in
      if let artworkURL = item.artworkURL {
        return RemoteMediaItem(artworkURL: artworkURL)
      } else {
        throw "Error"
      }
    }
  }
  
}

internal struct RemoteMediaItem {
  internal let artworkURL: URL
}

private extension Array where Element == RemoteMediaItem {
  func toModels() -> [MediaItem] {
    return map { MediaItem(artworkURL: $0.artworkURL ) }
  }
}
