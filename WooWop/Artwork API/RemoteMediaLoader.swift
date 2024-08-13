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
  
  public func loadMedia() async throws -> LoadMediaResult {
    // Call single method from API of ShazamClient.
    let result = await client.findMatch()
    // Use the result.
    switch result {
    case .match(let match):
      return LoadMediaResult.match(match)
    case .noMatch:
      return LoadMediaResult.noMatch
    case .error(let error):
      return LoadMediaResult.error(error)
    }
  }
}
