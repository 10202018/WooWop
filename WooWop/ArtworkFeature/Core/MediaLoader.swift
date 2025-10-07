//
//  MediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

/// Represents the possible outcomes of a media loading operation.
/// 
/// This enum encapsulates the different states that can result from attempting
/// to identify and load media information from an audio source.
public enum LoadMediaResult {
  /// Successfully matched one or more media items
  case match([MediaItem])
  
  /// No matching media was found in the database
  case noMatch
  
  /// An error occurred during the loading process
  case error(Error)
}

/// Protocol defining the interface for loading media information.
/// 
/// Implementers of this protocol are responsible for identifying songs
/// from audio input and returning relevant media information.
public protocol MediaLoader {
  /// Asynchronously loads media information from the current audio context.
  /// 
  /// This method typically involves audio recognition, database lookup,
  /// and metadata retrieval for the identified media.
  /// 
  /// - Returns: A `LoadMediaResult` indicating success, failure, or no match
  /// - Throws: Various errors related to audio processing or network issues
  func loadMedia() async throws -> LoadMediaResult
}
