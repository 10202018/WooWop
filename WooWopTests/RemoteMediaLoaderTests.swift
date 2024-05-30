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

public protocol HTTPClient {
  func findMatch(from: SHManagedSession)
}

public final class RemoteMediaLoader {
  private let client: HTTPClient
  private let session: SHManagedSession
  
  public init(client: HTTPClient, session: SHManagedSession) {
    self.client = client
    self.session = session
  }
  
  public func load() {
    client.findMatch(from: session)
  }
}

final class RemoteMediaLoaderTests: XCTestCase {

  func test_init_doesNotRequestMatchFromSession() {
    let session = SHManagedSession()
    let (client, _) = makeSUT(session: session)
    
    XCTAssertNil(client.requestedShazamSession)
  }
  
  func test_load_requestMatchFromSession() {
    let session = SHManagedSession()
    let (client, sut) = makeSUT(session: session)
    
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedShazamSessions, [session, session])
  }
  
  // MARK: - Helpers.
  /// An implementation of the HTTPClient protocol for testing purposes only.
  class HTTPClientSpy: HTTPClient {
    var requestedShazamSession: SHManagedSession?
    var requestedShazamSessions = [SHManagedSession]()

    func findMatch(from session: SHManagedSession) {
      requestedShazamSession = session
      requestedShazamSessions.append(session)
    }
  }
  
  private func makeSUT(session: SHManagedSession = SHManagedSession()) -> (client: HTTPClientSpy, sut: RemoteMediaLoader) {
    let client = HTTPClientSpy()
    let sut = RemoteMediaLoader(client: client, session: session)
    return (client, sut)
  }
}
