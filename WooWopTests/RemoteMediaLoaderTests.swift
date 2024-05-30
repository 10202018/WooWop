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
  func findMatch(from: SHManagedSession, completion: @escaping (Error) -> Void)
}

public final class RemoteMediaLoader {
  public enum Error: Swift.Error {
    case connectivity
  }
  
  private let client: HTTPClient
  private let session: SHManagedSession
  
  public init(client: HTTPClient, session: SHManagedSession) {
    self.client = client
    self.session = session
  }
  
  public func load(completion: @escaping (Error) -> Void = { _ in }) {
    client.findMatch(from: session) { error in
      completion(.connectivity)
    }
  }
}

final class RemoteMediaLoaderTests: XCTestCase {
  func test_init_doesNotRequestMatchFromSession() {
    let session = SHManagedSession()
    let (client, _) = makeSUT(session: session)
    
    XCTAssertTrue(client.requestedShazamSessions.isEmpty)
  }
  
  func test_load_requestMatchFromSession() {
    let session = SHManagedSession()
    let (client, sut) = makeSUT(session: session)
    
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedShazamSessions, [session, session])
  }
  
  func test_load_deliversErrorOnClientError() {
    let (client, sut) = makeSUT()
    
    var capturedError = [RemoteMediaLoader.Error]()
    sut.load() { capturedError.append($0) }
    
    let clientError = NSError(domain: "Test", code: 0)
    client.complete(with: clientError)
    
    XCTAssertEqual(capturedError, [.connectivity])
  }
  
  // MARK: - Helpers.
  /// An implementation of the HTTPClient protocol for testing purposes only.
  class HTTPClientSpy: HTTPClient {
    private var messages = [(session: SHManagedSession, completion: (Error) -> Void)]()
    var requestedShazamSessions: [SHManagedSession] {
      return messages.map { result in
        result.session
      }
    }

    func findMatch(from session: SHManagedSession, completion: @escaping (Error) -> Void) {
      messages.append((session, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
      messages[index].completion(error)
    }
  }
  
  private func makeSUT(session: SHManagedSession = SHManagedSession()) -> (client: HTTPClientSpy, sut: RemoteMediaLoader) {
    let client = HTTPClientSpy()
    let sut = RemoteMediaLoader(client: client, session: session)
    return (client, sut)
  }
}
