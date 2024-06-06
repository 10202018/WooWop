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
  func loadMedia(completion: @escaping (LoadMediaResult) -> Void) async throws {
    // Call single method from API of ShazamClient.
    let result = await ShazamClient().executeSessionAndMatch()
    // Use the result.
    switch result {
    case .match(let match):
      completion(.match(match.mediaItems))
    case .noMatch(_):
      completion(.error("Error: No match found"))
    case .error(let error, _):
      completion(.error("Error: \(error)"))
    }
  }
}
