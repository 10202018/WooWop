//
//  WooWopTests.swift
//  WooWopTests
//
//  Created by Jah Morris-Jones on 5/21/24.
//

import WooWop
import ShazamKit
import XCTest

extension SHManagedSession: Equatable {
  public static func == (lhs: SHManagedSession, rhs: SHManagedSession) -> Bool {
    return (lhs.self === rhs.self)
  }
}

final class RemoteMediaLoaderTests: XCTestCase {
  func test_init_doesNotRequestMatchFromSession() {
    let session = SHManagedSession()
    let (client, _) = makeSUT(session: session)
    
    XCTAssertTrue(client.requestedShazamSessions.isEmpty)
  }
  
  func test_load_requestsMatchFromSession() {
    let session = SHManagedSession()
    let (client, sut) = makeSUT(session: session)
    
    sut.load() { _ in }
    
    XCTAssertEqual(client.requestedShazamSessions, [session])
  }
  
  func test_loadTwice_requestsMatchFromSession() {
    let session = SHManagedSession()
    let (client, sut) = makeSUT(session: session)
    
    sut.load() { _ in }
    sut.load() { _ in }
    
    XCTAssertEqual(client.requestedShazamSessions, [session, session])
  }
  
  func test_load_deliversErrorOnClientError() {
    let (client, sut) = makeSUT()
    
    expect(sut, toCompleteWithError: .error(RemoteMediaLoader.Error.connectivity)) {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(withError: clientError)
    }
  }
  
  func test_load_deliversNoMatchesFromSession() {
    let (client, sut) = makeSUT()
    
    var capturedResults = [RemoteMediaLoader.Result]()
    sut.load { capturedResults.append($0) }
    
    client.completeWithNoMatches()
    
    XCTAssertEqual(capturedResults, [.noMatch])
  }
  
  func test_load_deliversMatchesFromSession() {
    let session = SHManagedSession()
    let (client, sut) = makeSUT(session: session)
    
    let item1 = SHMediaItem(properties: [.artworkURL : "http://a-url-for-artwork", .shazamID: UUID().uuidString])
    let item2 = SHMediaItem(properties: [.artworkURL : "http://a-second-url-for-artwork", .shazamID: UUID().uuidString])
    let item3 = SHMediaItem(properties: [.artworkURL :  "http://a-third-url-for-artwork", .shazamID: UUID().uuidString])
    
    var capturedResults = [RemoteMediaLoader.Result]()
    sut.load { capturedResults.append($0) }
    
    let matchedMediaItems = [item1, item2, item3]
    client.complete(withMatchedMedia: matchedMediaItems)
    
    XCTAssertEqual(capturedResults, [.match(matchedMediaItems)])
  }
  
  func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
    let client = ClientSpy()
    let session = SHManagedSession()
    var sut: RemoteMediaLoader? = RemoteMediaLoader(client: client, session: session)
    
    var capturedResults = [RemoteMediaLoader.Result]()
    sut!.load { capturedResults.append($0) }

    sut = nil
    client.complete(withMatchedMedia: [
      SHMediaItem(properties: [.artworkURL : "any-url"])
    ])
    
    XCTAssertTrue(capturedResults.isEmpty)
  }
  
  // MARK: - Helpers.
  /// An implementation of the Client protocol for testing purposes only.
  class ClientSpy: Client {
    private var messages = [(session: SHManagedSession, completion: (ClientResult) -> Void)]()
    var requestedShazamSessions: [SHManagedSession] {
      return messages.map { result in
        result.session
      }
    }

    func findMatch(from session: SHManagedSession, completion: @escaping (ClientResult) -> Void) {
      messages.append((session, completion))
    }
    
    func complete(withError error: Error, at index: Int = 0) {
      messages[index].completion(.error(error))
    }
    
    func completeWithNoMatches(at index: Int = 0) {
      messages[index].completion(.noMatch)
    }
    
    func complete(withMatchedMedia items: [SHMediaItem], at index: Int = 0) {
      messages[index].completion(.match(items))
    }
  }
  
  private func makeSUT(session: SHManagedSession = SHManagedSession()) -> (client: ClientSpy, sut: RemoteMediaLoader) {
    let client = ClientSpy()
    let sut = RemoteMediaLoader(client: client, session: session)
    trackForMemoryLeaks(client)
    trackForMemoryLeaks(sut)
    return (client, sut)
  }
  
  private func expect(_ sut: RemoteMediaLoader, toCompleteWithError error: RemoteMediaLoader.Result, when action: () -> Void, file: StaticString = #filePath,
                      line: UInt = #line) {
    var capturedError = [RemoteMediaLoader.Result]()
    sut.load() { capturedError.append($0) }

    action()
    
    XCTAssertEqual(capturedError, [error], file: file, line: line)
  }
  
  private func trackForMemoryLeaks(
      _ instance: AnyObject,
      file: StaticString = #file,
      line: UInt = #line) {
        addTeardownBlock { [weak instance] in
          XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
  }
}
