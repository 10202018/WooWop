//
//  WooWopTests.swift
//  WooWopTests
//
//  Created by Jah Morris-Jones on 5/21/24.
//

import ShazamKit
import XCTest

class RemoteMediaLoader {
  let client: HTTPClient
  
  init(client: HTTPClient) {
    self.client = client
  }
  
  func load() {
    client.get(from: SHManagedSession())
  }
}

protocol HTTPClient {
  func get(from: SHManagedSession)
}

/// An implementation of the HTTPClient protocol for testing purposes only.
class HTTPClientSpy: HTTPClient {
  func get(from session: SHManagedSession) {
    requestedShazamSession = session
  }
  
  var requestedShazamSession: SHManagedSession?
}

final class RemoteMediaLoaderTests: XCTestCase {

  func test_init_doesNotRequestMatchFromSession() {
    let client = HTTPClientSpy()
    _ = RemoteMediaLoader(client: client)
    
    XCTAssertNil(client.requestedShazamSession)
  }

}
