//
//  RemoteMediaLoaderTests.swift
//  WooWopTests
//
//  Created by Jah Morris-Jones on 8/12/24.
//

import ShazamKit
import WooWop
import XCTest

final class RemoteMediaLoaderTests: XCTestCase {

  func test_init_doesNotRequestMatchFromSession() {
    let client = ShazamClientSpy()
    _ = RemoteMediaLoader(client: client)
    
    XCTAssertNil(client.requestedShazamSession)
  }
  
  func test_loadMedia_requestMatchFromSessionIsSuccessful() async throws {
    let client = ShazamClientSpy()
    let sut = RemoteMediaLoader(client: client)
    
    _ = try await sut.loadMedia()
    
    XCTAssertEqual(client.requestedShazamSession, true)
  }
}


/// An implementation of the HTTPClient protocol for testing purposes only.
class ShazamClientSpy: ShazamClient {
  func findMatch() async -> ClientResult {
    requestedShazamSession = true
    return ClientResult.noMatch
  }
  
  var requestedShazamSession: Bool?
}
