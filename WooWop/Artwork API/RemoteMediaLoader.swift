//
//  RemoteMediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

public final class RemoteMediaLoader: MediaLoader {
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  private let client: Client
  private let session: SHManagedSession
  
  public typealias Result = LoadMediaResult<Error>
  
  public init(client: Client, session: SHManagedSession) {
    self.client = client
    self.session = session
  }
  
  func loadMedia(completion: @escaping (Result) -> Void) async {
    client.findMatch(from: session) { [weak self] result in
      guard self != nil else { return }
      switch result {
      case let .match(items):
        completion(.match(items))
      case .noMatch:
        completion(.noMatch)
      case .error:
        completion(.error(.connectivity))
      }

    }
  }
}
