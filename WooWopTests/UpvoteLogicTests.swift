import XCTest
import MultipeerConnectivity
@testable import WooWop

final class UpvoteLogicTests: XCTestCase {

    func testAcceptsUpvoteFromOtherListener() throws {
        let manager = MultipeerManager()
        let request = SongRequest(title: "Song A", artist: "Artist", requesterName: "requester")
        manager.receivedRequests = [request]

        let data = try JSONEncoder().encode(MultipeerManager.QueueMessage.upvote(request.id))
        let voter = MCPeerID(displayName: "voter-1")
        let session = MCSession(peer: MCPeerID(displayName: "local-test"))

        let exp = expectation(description: "upvote processed")
        manager.session(session, didReceive: data, fromPeer: voter)

        DispatchQueue.main.async {
            guard let idx = manager.receivedRequests.firstIndex(where: { $0.id == request.id }) else {
                XCTFail("Request missing after upvote")
                exp.fulfill()
                return
            }

            XCTAssertEqual(manager.receivedRequests[idx].upvotes, 1)
            XCTAssertTrue(manager.receivedRequests[idx].upvoters.contains("voter-1"))
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
    }

    func testIgnoresSelfUpvote() throws {
        let manager = MultipeerManager()
        // The requester has the same displayName as the voter
        let request = SongRequest(title: "Song B", artist: "Artist B", requesterName: "self-peer")
        manager.receivedRequests = [request]

        let data = try JSONEncoder().encode(MultipeerManager.QueueMessage.upvote(request.id))
        let voter = MCPeerID(displayName: "self-peer")
        let session = MCSession(peer: MCPeerID(displayName: "local-test"))

        let exp = expectation(description: "self upvote ignored")
        manager.session(session, didReceive: data, fromPeer: voter)

        DispatchQueue.main.async {
            guard let idx = manager.receivedRequests.firstIndex(where: { $0.id == request.id }) else {
                XCTFail("Request missing after self-upvote attempt")
                exp.fulfill()
                return
            }

            XCTAssertEqual(manager.receivedRequests[idx].upvotes, 0)
            XCTAssertFalse(manager.receivedRequests[idx].upvoters.contains("self-peer"))
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
    }

    func testIgnoresDuplicateUpvote() throws {
        let manager = MultipeerManager()
        let request = SongRequest(title: "Song C", artist: "Artist C", requesterName: "someone")
        manager.receivedRequests = [request]

        let data = try JSONEncoder().encode(MultipeerManager.QueueMessage.upvote(request.id))
        let voter = MCPeerID(displayName: "voter-1")
        let session = MCSession(peer: MCPeerID(displayName: "local-test"))

        // First upvote
        manager.session(session, didReceive: data, fromPeer: voter)
        // Second upvote (duplicate)
        manager.session(session, didReceive: data, fromPeer: voter)

        let exp = expectation(description: "duplicate upvote ignored")
        DispatchQueue.main.async {
            guard let idx = manager.receivedRequests.firstIndex(where: { $0.id == request.id }) else {
                XCTFail("Request missing after duplicate upvote attempts")
                exp.fulfill()
                return
            }

            XCTAssertEqual(manager.receivedRequests[idx].upvotes, 1)
            XCTAssertEqual(manager.receivedRequests[idx].upvoters.filter { $0 == "voter-1" }.count, 1)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
    }
}
