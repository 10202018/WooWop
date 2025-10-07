//
//  Client.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 6/6/24.
//

import Foundation
import ShazamKit

/// A concrete implementation of ShazamClient using Apple's SHManagedSession.
/// 
/// This class provides a managed audio recognition session that can automatically
/// handle audio capture, processing, and matching against Shazam's catalog.
/// It follows the Singleton pattern for consistent session management.
public class SHManagedSessionClient: ShazamClient {
  /// The underlying Shazam managed session that handles audio recognition
  var session: SHManagedSession
  
  /// Initializes the client with a managed session.
  /// 
  /// - Parameter session: The SHManagedSession to use for audio recognition.
  ///                      Defaults to a new instance if not provided.
  public init(session: SHManagedSession = SHManagedSession()) {
    self.session = session
  }
  
  /// Performs asynchronous song identification using the managed session.
  /// 
  /// This method triggers the audio recognition process and waits for results
  /// from Shazam's service. It handles the conversion from Shazam's result format
  /// to the app's internal ClientResult format.
  /// 
  /// - Returns: A ClientResult containing matched songs, no match indication, or error details
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
