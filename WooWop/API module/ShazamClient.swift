//
//  ShazamClient.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/17/24.
//

import Foundation
import ShazamKit

// MARK: - API Module

// Singleton (capital "S")
/// The Shazam API client.
class ShazamClient {
  static let instance = ShazamClient()
  
  // Set up the session
  /// An object that records and matches a recording with captured sound in the Shazam catalog or your
  /// custom catalog.
  private var shazamSession = SHManagedSession()
  
  /// Makes  an asynchrnous request to match the signature (hashed version passed to and from client) of
  /// the song from the current session.
  /// Returns:
  /// - an object that represents the metadata for a reference signature.
  private func executeSessionAndMatch() async -> SHSession.Result {
    return await shazamSession.result()
  }
}

extension ShazamClient {

  func getSessionResult() async -> SHMediaItem? {
    let result = await executeSessionAndMatch()
    // Use the result.
    switch await shazamSession.result() {
    case .match(let match):
      return match.mediaItems.first
    case .noMatch(_): return nil
    case .error(let error, _): return nil
    }
  }
}
