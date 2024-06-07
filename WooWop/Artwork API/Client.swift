//
//  Client.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 6/6/24.
//

import Foundation
import ShazamKit

public enum ClientResult {
  case match([SHMediaItem])
  case noMatch
  case error(Error)
}

public protocol Client {
  func findMatch(from: SHManagedSession, completion: @escaping (ClientResult) -> Void)
}
