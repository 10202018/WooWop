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
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        let shazamID = item.shazamID
        return RemoteMediaItem(artworkURL: artworkURL, title: title, artist: artist, shazamID: shazamID)
      } else {
        throw "Error: could not map type `SHMediaItem` to type `RemoteMediaItem`"
      }
    }
  }
  
}
