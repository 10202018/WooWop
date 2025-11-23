//
//  RemoteMediaLoader.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/20/24.
//

import Foundation
import ShazamKit

extension String: Error {}

/// Implementation of MediaLoader that uses remote Shazam services for song identification.
/// 
/// This class orchestrates the process of identifying songs using a ShazamClient,
/// mapping the results to internal data structures, and returning them in a format
/// suitable for the application's UI components.
public class RemoteMediaLoader: MediaLoader {
  /// The Shazam client used for audio recognition and song identification
  private var client: ShazamClient
  
  /// Initializes the loader with a specific Shazam client.
  /// 
  /// - Parameter client: The ShazamClient implementation to use for song identification
  public init(client: ShazamClient) {
    self.client = client
  }
  
  /// Asynchronously loads media information using remote Shazam services.
  /// 
  /// This method coordinates the entire identification process: capturing audio,
  /// sending it to Shazam's servers, processing the response, and converting
  /// the results to the app's internal MediaItem format.
  /// 
  /// - Returns: LoadMediaResult containing matched songs, no match, or error information
  /// - Throws: Various errors related to network issues, audio processing, or data mapping
  public func loadMedia() async throws ->  LoadMediaResult {
    // Call single method from API of ShazamClient.
    let result = await client.findMatch()
    // Use the result.
    switch result {
    case .match(let matches):
      return RemoteMediaLoader.map(matches)
    case .noMatch:
      return LoadMediaResult.noMatch
    case .error(let error):
      return LoadMediaResult.error(error)
    }
  }
  
  /// Maps Shazam API results to internal LoadMediaResult format.
  /// 
  /// This private method handles the conversion from SHMediaItem objects to
  /// the app's MediaItem format, including error handling for mapping failures.
  /// 
  /// - Parameter matches: Array of SHMediaItem objects from Shazam
  /// - Returns: LoadMediaResult with successfully mapped MediaItem objects or error
  private static func map(_ matches: [SHMediaItem]) -> LoadMediaResult {
    do {
      let mediaItems = try RemoteMediaMapper.map(matches)
      return LoadMediaResult.match(mediaItems.toModels())
    } catch(let error) {
      return LoadMediaResult.error(error)
    }
  }

  /// Performs a simple text-based search using the iTunes Search API as a fallback
  /// when a direct Shazam text search isn't available. Maps results to `MediaItem`.
  ///
  /// - Parameter term: The search term to query for
  /// - Returns: LoadMediaResult with matches or noMatch/error
  public func search(term: String) async -> LoadMediaResult {
    guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=50") else {
      return LoadMediaResult.noMatch
    }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      
      struct ITunesResponse: Decodable {
        struct ITunesItem: Decodable {
          let trackName: String?
          let artistName: String?
          let artworkUrl100: String?
        }
        let results: [ITunesItem]
      }

      let resp = try JSONDecoder().decode(ITunesResponse.self, from: data)
      
      // Debug: Print raw results count
      print("iTunes API returned \(resp.results.count) raw results for search: '\(term)'")
      
      let items: [MediaItem] = resp.results.compactMap { it in
        guard var artwork = it.artworkUrl100 else { 
          return nil 
        }
        
        // iTunes artwork URLs include size tokens like 100x100 - prefer a higher-res variant when possible
        // Replace only if current resolution is lower than 600x600 for better quality artwork.
        if let range = artwork.range(of: "\\d+x\\d+", options: .regularExpression, range: nil, locale: nil) {
          let sizeString = String(artwork[range])
          
          // Extract width from the size string (e.g., "100" from "100x100")
          if let xIndex = sizeString.firstIndex(of: "x"),
             let currentWidth = Int(String(sizeString[..<xIndex])) {
            
            if currentWidth < 600 {
              artwork.replaceSubrange(range, with: "600x600")
            }
          }
        }
        
        guard let artURL = URL(string: artwork) else { 
          return nil 
        }
        
        return MediaItem(artworkURL: artURL, title: it.trackName, artist: it.artistName, shazamID: nil)
      }
      
      // Smart deduplication that groups by song title and keeps the most canonical version
      var titleGroups: [String: [MediaItem]] = [:]
      
      // Group items by normalized title (ignoring artist differences)
      for item in items {
        let normalizedTitle = item.title?
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .lowercased()
          // Only remove common metadata patterns in parentheses, not song titles
          .replacingOccurrences(of: "\\s*\\(feat[^)]*\\)\\s*", with: "", options: .regularExpression) // Remove feat. info
          .replacingOccurrences(of: "\\s*\\(remix\\)\\s*", with: "", options: .regularExpression) // Remove remix labels
          .replacingOccurrences(of: "\\s*\\(remaster[^)]*\\)\\s*", with: "", options: .regularExpression) // Remove remaster info
          .replacingOccurrences(of: "\\s*\\(radio edit\\)\\s*", with: "", options: .regularExpression) // Remove radio edit
          .replacingOccurrences(of: "\\s*\\(acoustic\\)\\s*", with: "", options: .regularExpression) // Remove acoustic labels
          .replacingOccurrences(of: "\\s*\\(live\\)\\s*", with: "", options: .regularExpression) // Remove live labels
          .replacingOccurrences(of: "\\s*\\[[^]]*\\]\\s*", with: "", options: .regularExpression) // Remove bracketed info
          .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // Normalize whitespace to single spaces
          .replacingOccurrences(of: "[^a-z0-9 ()]", with: "", options: .regularExpression) // Remove special chars but keep spaces and parentheses
          .trimmingCharacters(in: .whitespaces) ?? ""
        
        if titleGroups[normalizedTitle] == nil {
          titleGroups[normalizedTitle] = []
        }
        titleGroups[normalizedTitle]?.append(item)
      }
      
      var uniqueItems: [MediaItem] = []
      
      // For each title group, pick the best version
      // Sort by title to ensure consistent ordering across searches
      for (titleKey, versions) in titleGroups.sorted(by: { $0.key < $1.key }) {
        if versions.count == 1 {
          // Only one version, keep it
          uniqueItems.append(versions[0])
        } else {
          // Multiple versions - pick the most canonical one
          let bestVersion = versions.max { v1, v2 in
            calculateCanonicalScore(v1) < calculateCanonicalScore(v2)
          }
          
          if let best = bestVersion {
            uniqueItems.append(best)
          }
        }
      }
      
      // Sort final results by search relevance first, then canonical score
      let searchTermLower = term.lowercased()
      uniqueItems.sort { item1, item2 in
        let score1 = calculateCanonicalScore(item1) + calculateSearchRelevance(item1, searchTerm: searchTermLower)
        let score2 = calculateCanonicalScore(item2) + calculateSearchRelevance(item2, searchTerm: searchTermLower)
        return score1 > score2
      }
      
      // Debug: Print deduplication results
      print("After smart deduplication: \(items.count) -> \(uniqueItems.count) items")
      
      return uniqueItems.isEmpty ? LoadMediaResult.noMatch : LoadMediaResult.match(uniqueItems)
    } catch {
      return LoadMediaResult.error(error)
    }
  }
  
  /// Calculates a score to determine the most "canonical" version of a song
  /// Higher score = more canonical/preferred
  private func calculateCanonicalScore(_ item: MediaItem) -> Int {
    var score = 0
    
    let title = item.title?.lowercased() ?? ""
    let artist = item.artist?.lowercased() ?? ""
    
    // Heavily prefer non-instrumental versions
    if !title.contains("instrumental") && !title.contains("karaoke") {
      score += 1000
    }
    
    // Prefer non-remix versions
    if !title.contains("remix") && !title.contains("remaster") && !title.contains("radio edit") {
      score += 500
    }
    
    // Major bonus for authentic/original artists vs compilation albums
    // Heavily penalize known compilation/tribute artists
    let compilationArtists = ["can you flow", "various artists", "tribute", "karaoke", "instrumental", 
                             "cover", "sound alike", "hits", "greatest", "collection", "best of",
                             "compilation", "playlist", "anthology"]
    
    let isCompilation = compilationArtists.contains { keyword in
      artist.contains(keyword)
    }
    
    if isCompilation {
      score -= 5000 // Heavy penalty for compilation albums
    } else {
        // Moderate bonus for likely real artists (shorter names, no business words)
        let artistWordCount = artist.split(separator: " ").count
        let hasBusinessWords = artist.contains("records") || artist.contains("music") || 
                              artist.contains("entertainment") || artist.contains("productions")
        
        if artistWordCount <= 3 && !hasBusinessWords {
          score += 1000 // Moderate bonus for likely real artist names (increased from 2 to 3 words)
        }
    }
    
    // Prefer versions with explicit features (more complete info) but not for compilation artists
    if !isCompilation && (title.contains("feat") || artist.contains("feat")) {
      score += 300
    }
    
    // Prefer more descriptive artist names (usually original artists), but not if it's a compilation
    if !isCompilation {
      score += (item.artist?.count ?? 0) * 2
    }
    
    // Slight preference for longer titles (usually more complete), but less weight than artist authenticity
    score += (item.title?.count ?? 0)
    
    return score
  }
  
  /// Calculates a search relevance score based on how well the item matches the search term
  /// Higher score = more relevant to what the user searched for
  private func calculateSearchRelevance(_ item: MediaItem, searchTerm: String) -> Int {
    var relevanceScore = 0
    
    let title = item.title?.lowercased() ?? ""
    let artist = item.artist?.lowercased() ?? ""
    let searchWords = searchTerm.split(separator: " ").map { String($0) }
    
    // Major bonus for exact artist name match
    for word in searchWords {
      if artist.contains(word) {
        relevanceScore += 1000
      }
      
      if title.contains(word) {
        relevanceScore += 500
      }
    }
    
    return relevanceScore
  }
}

/// Extension providing conversion from RemoteMediaItem to MediaItem.
/// 
/// This extension adds functionality to convert arrays of internal RemoteMediaItem
/// objects to user-facing MediaItem objects that can be used throughout the app.
private extension Array where Element == RemoteMediaItem {
  /// Converts RemoteMediaItem objects to MediaItem objects.
  /// 
  /// - Returns: Array of MediaItem objects suitable for UI consumption
  func toModels() -> [MediaItem] {
    return map { MediaItem(artworkURL: $0.artworkURL, title: $0.title, artist: $0.artist, shazamID: $0.shazamID) }
  }
}
