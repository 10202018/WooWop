//
//  MediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

public enum LoadMediaResult {
  case match([SHMediaItem])
  case noMatch
  case error(Error)
}

public protocol MediaLoader {
  func loadMedia(completion: @escaping (LoadMediaResult) -> Void) async
}
