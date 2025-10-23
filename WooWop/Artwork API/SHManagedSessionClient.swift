//
//  Client.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 6/6/24.
//

import Foundation
import ShazamKit

/// SHManagedSessionClient
///
/// A concrete implementation of `ShazamClient` built on top of Apple's
/// `SHManagedSession`.
/// Singleton (capital "S") to indicate it's a specific implementation of the
/// ShazamClient protocol.
///
///   may call back on internal threads. Callers should assume `findMatch()` is
///   asynchronous and may be resumed on a non-main thread; dispatch to the
///   main queue when updating UI.
/// - This implementation intentionally keeps a lightweight wrapper rather than
///   exposing `SHManagedSession` directly so the app can swap implementations
///   during testing or when using a different recognition backend.
///
/// Thread-safety & lifecycle:
/// - `SHManagedSession` manages its own lifecycle; if you need a shared
///   instance across the app, instantiate and reuse a single `SHManagedSessionClient`.
/// - Avoid creating many managed sessions concurrently — prefer reusing an
///   existing client to conserve system resources.
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
