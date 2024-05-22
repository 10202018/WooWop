//
//  MediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

protocol MediaLoader {
  func loadMedia() async throws -> SHMediaItem
}
