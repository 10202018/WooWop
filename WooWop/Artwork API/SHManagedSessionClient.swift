//
//  Client.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 6/6/24.
//

import Foundation
import ShazamKit

// Singleton (capital "S")
/// The Shazam API client.
public class SHManagedSessionClient: ShazamClient {
  /// An object that records and matches a recording with captured sound in the Shazam catalog or your
  /// custom catalog.
  var session: SHManagedSession
  
  public init(session: SHManagedSession = SHManagedSession()) {
    self.session = session
  }
  
  /// Makes  an asynchrnous request to match the signature (hashed version passed to and from client) of
  /// the song from the current session.
  public func findMatch() async -> ClientResult {
    let result = await session.result()
    switch result {
    case let .match(returnedMatches):
      return ClientResult.match(returnedMatches.mediaItems)
    case .noMatch(_):
      return ClientResult.noMatch
    case let .error(error, _):
      return ClientResult.error(error)
    }
  }
}
