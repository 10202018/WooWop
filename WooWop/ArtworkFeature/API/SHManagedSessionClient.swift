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
class SHManagedSessionClient: Client {
  /// An object that records and matches a recording with captured sound in the Shazam catalog or your
  /// custom catalog.
  var session: SHManagedSessionClient
  
  init(session: SHManagedSessionClient) {
    self.session = session
  }
  
  /// Makes  an asynchrnous request to match the signature (hashed version passed to and from client) of
  /// the song from the current session.
  func findMatch(from session: SHManagedSession, completion: @escaping (ClientResult) -> Void) async {
    let result = await session.result()
    switch result {
    case let .match(returnedMatch):
      completion(.match([returnedMatch.mediaItems.first!]))
    case .noMatch(_):
      completion(.noMatch)
    case let .error(error, _):
      completion(.error(error))
    }
  }
}

class ShazamClient {
  
  // Set up the session
  /// An object that records and matches a recording with captured sound in the Shazam catalog or your
  /// custom catalog.
  private var shazamSession = SHManagedSession()
  
  /// Makes  an asynchrnous request to match the signature (hashed version passed to and from client) of
  /// the song from the current session.
  /// Returns:
  /// - an object that represents the metadata for a reference signature.
  func executeSessionAndMatch() async -> SHSession.Result {
    return await shazamSession.result()
  }
  
  func getSessionResult() async -> SHMediaItem? {
    // Use the result.
    let shazamSession = SHManagedSession()
    switch await shazamSession.result() {
    case .match(let match):
      return match.mediaItems.first
    case .noMatch(_): return nil
    case .error(let error, _): return nil
    }
  }
}
