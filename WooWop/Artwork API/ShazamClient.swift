//
//  ShazamClient.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/17/24.
//

import Foundation
import ShazamKit

/// Represents the possible outcomes of a Shazam song identification attempt.
/// 
/// This enum encapsulates the different results that can occur when trying
/// to identify a song using Shazam's audio recognition service.
public enum ClientResult {
  /// Successfully identified one or more matching songs
  case match([SHMediaItem])
  
  /// No matching songs were found in Shazam's database
  case noMatch
  
  /// An error occurred during the identification process
  case error(Error)
}

/// Protocol defining the interface for Shazam audio recognition clients.
/// 
/// Implementers of this protocol are responsible for interfacing with
/// Shazam's song identification services and returning recognition results.
public protocol ShazamClient {
  /// Attempts to identify the currently playing audio using Shazam's service.
  /// 
  /// This method performs audio capture and recognition, querying Shazam's
  /// database to find matching songs based on the audio fingerprint.
  /// 
  /// - Returns: A `ClientResult` indicating the outcome of the identification attempt
  func findMatch() async -> ClientResult
}
