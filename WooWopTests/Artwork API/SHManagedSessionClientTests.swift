


import WooWop
import Foundation
import ShazamKit
import XCTest

struct ManagedSessionWrapper: Hashable {
    let session: SHManagedSession

    func hash(into hasher: inout Hasher) {
        // Hash properties of SHManagedSession that determine uniqueness
        // You might need to use reflection if properties are not accessible
    }

    static func == (lhs: ManagedSessionWrapper, rhs: ManagedSessionWrapper) -> Bool {
        // Compare properties of SHManagedSession for equality
    }
}

protocol ManagedSession {
  var session: SHManagedSession { get set}
  func result() async -> SHSession.Result
}

class SHManagedSessionClient {
  private let session: ManagedSession
  
  init(session: ManagedSession) {
    self.session = session
  }
  
  func findMatch(completion: @escaping (ClientResult) -> Void) async {
    let result = await session.result()
    switch result {
    case .match(let match):
      completion(.match(match.mediaItems))
    case .noMatch(_):
      completion(.noMatch)
    case .error(let error, _):
      completion(.error(error))
    }
  }
}

class SHManagedSessionClientTests: XCTestCase {
  
  func test() async throws {
    let session = SHManagedSession()
    let spy = SHManagedSessionSpy(session: <#T##SHManagedSession#>)
    let sut = SHManagedSessionClient(session: session)
    
    await sut.findMatch() { _ in }
    
    XCTAssertEqual(session.requestedShazamSessions, [ ])
  }

//  func test_findMatchFromSession_failsOnRequestError() async {
//    let session = SHManagedSessionSpy()
//    let error = NSError(domain: "any error", code: 1)
////    session.stub(result: result)
//    
//    let sut = SHManagedSessionClient(session: session)
//    
//    let exp = expectation(description: "Wait for completion")
//    
//    await sut.findMatch(from: session) { result in
//      switch result {
//      case let .error(receivedError as NSError):
//        XCTAssertEqual(receivedError, error)
//      default:
//        XCTFail("Expected failure with error \(error), got \(result) instead.")
//      }
//      
//      exp.fulfill()
//    }
//    
//    await fulfillment(of: [exp], timeout: 1, enforceOrder: true)
//  }

  class SHManagedSessionSpy: ManagedSession {
    var session: SHManagedSession
    
    init(session: SHManagedSession) {
      self.session = session
    }
    
    var requestedShazamSessions = [SHManagedSession]()
    private var stubs = [ManagedSessionWrapper : Stub]()
    
    private struct Stub {
      let error: Error?
    }
    
    func result() async -> SHSession.Result {
      let error = NSError(domain: "Test", code: 0)
      requestedShazamSessions.append(session)
      return .error(error, SHSignature())
    }

    
  }
  
}



