//
//  ShazamClient.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/17/24.
//

import Foundation
import ShazamKit

// Singleton (capital "S")
class ShazamClient {
  static let instance = ShazamClient()
  
  // Set up the session
  private var shazamSession = SHManagedSession()
  
  private init() {}
  
  func getSessionResult() async -> SHMediaItem? {
    // Use the result.
    switch await shazamSession.result() {
    case .match(let match):
      return match.mediaItems.first
    case .noMatch(_): return nil
    case .error(let error, _): return nil
    }
  }
}
