//
//  RemoteMediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

extension String: Error {}

class RemoteMediaLoader: MediaLoader {
  func loadMedia() async throws -> SHMediaItem {
    // Call single method from API of ShazamClient.
    let result = await ShazamClient().executeSessionAndMatch()
    // Use the result.
    switch result {
    case .match(let match):
      return match.mediaItems.first!
    case .noMatch(_):
      throw "Error: No match found"
    case .error(let error, _):
      throw "Error: \(error)"
    }
  }
}
