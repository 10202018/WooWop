//
//  ShazamClient.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/17/24.
//

import Foundation
import ShazamKit

public enum ClientResult {
  case match([SHMediaItem])
  case noMatch
  case error(Error)
}

public protocol ShazamClient {
  func findMatch() async -> ClientResult
}
