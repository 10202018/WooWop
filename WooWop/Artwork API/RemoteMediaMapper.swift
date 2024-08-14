//
//  RemoteMediaMapper.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 8/13/24.
//

import Foundation
import ShazamKit

internal final class RemoteMediaMapper {
  let items = [RemoteMediaItem]()
  
  internal static func map(_ items: [SHMediaItem]) throws -> [RemoteMediaItem] {
    return try items.map { item in
      if let artworkURL = item.artworkURL {
        return RemoteMediaItem(artworkURL: artworkURL)
      } else {
        throw "Error: could not map type `SHMediaItem` to type `RemoteMediaItem`"
      }
    }
  }
  
}
