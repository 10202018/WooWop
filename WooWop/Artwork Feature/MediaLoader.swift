//
//  MediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

public enum LoadMediaResult<Error: Swift.Error> {
  case match([SHMediaItem])
  case noMatch
  case error(Error)
}

extension LoadMediaResult: Equatable where Error: Equatable { }

protocol MediaLoader {
  associatedtype Error: Swift.Error
  func loadMedia(completion: @escaping (LoadMediaResult<Error>) -> Void) async throws
}
