//
//  SHManagedSessionClient.swift
//  WooWopTests
//
//  Created by Jah Morris-Jones on 6/11/24.
//

import XCTest
import ShazamKit
import WooWop


protocol ShazamSession {
  func result() async throws -> SHSession.Result // findMatch
}

//class SHManagedSessionWrapper: ShazamSession, Client {
//    private let session: SHManagedSession
//
//    init(session: SHManagedSession = SHManagedSession()) {
//        self.session = session
//    }
//
//    func result() async throws -> SHSession.Result {
//      await session.result()
//    }
//}

class MockShazamSession: ShazamSession {
  let mockResult: SHSession.Result
  
  init(mockResult: SHSession.Result) {
    self.mockResult = mockResult
  }
  
  func result() async throws  -> SHSession.Result {
    return mockResult
  }
}

extension String: Error { }

class SHManagedSessionClient: Client, ShazamSession {
  let session: MockShazamSession
  
  init(session: MockShazamSession) {
    self.session = session
  }

  func result() async throws -> SHSession.Result {
    await session.result()
  }
  
  func findMatch(from session: SHManagedSession, completion: @escaping (ClientResult) -> Void) async {
    let result = await session.result()
    switch result {
    case let .match(match):
      completion(.match([match.mediaItems.first!]))
    case .noMatch(_):
      completion(.noMatch)
    case let .error(error, _):
      completion(.error(error))
    }
  }
}

class SHMatchSub: SHMatch {
  var mediaItem: SHMediaItem
  
  init(mediaItem: SHMediaItem) {
    self.mediaItem = mediaItem
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class SHManagedSessionClientTests: XCTestCase {
  
  func test_isMatching() async {
    let shazamSession = SHManagedSession()
    
    //    let state = await session.state
    
    // Call findMatch
//    let client = SHManagedSessionClient(session: shazamSession)
//    await client.findMatch(from: shazamSession) { _ in }
    
    ///
    // 1. Create the Mock Data
    let mockMediaItem = SHMediaItem(properties: [
        .shazamID: "12345",
        .artworkURL: "Test-url"
    ])
    let match = SHMatchSub(mediaItem: mockMediaItem)
    
    // 2. Set Up the Mock Session
    let mockSession = MockShazamSession(mockResult: .match(match)) // Simulate a match
    let client = SHManagedSessionClient(session: mockSession)
    await client.findMatch(from: shazamSession) { _ in }
    
    
    XCTAssertEqual(client.states, [.matching])
  }
}
