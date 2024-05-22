//
//  WooWopTests.swift
//  WooWopTests
//
//  Created by Jah Morris-Jones on 5/21/24.
//

import ShazamKit
import XCTest

extension SHManagedSession: Equatable {
  public static func == (lhs: SHManagedSession, rhs: SHManagedSession) -> Bool {
    return (lhs.self === rhs.self)
  }
}

class RemoteMediaLoader {
  let client: HTTPClient
  let session: SHManagedSession
  
  init(client: HTTPClient, session: SHManagedSession) {
    self.client = client
    self.session = session
  }
  
  func load() {
    client.get(from: session)
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
    let session = SHManagedSession()
    let client = HTTPClientSpy()
    _ = RemoteMediaLoader(client: client, session: session)
    
    XCTAssertNil(client.requestedShazamSession)
  }
  
  func test_load_requestMatchFromSession() {
    let session = SHManagedSession()
    let client = HTTPClientSpy()
    let sut = RemoteMediaLoader(client: client, session: session)
    
    sut.load()
    
    XCTAssertEqual(client.requestedShazamSession, session)
  }

}
