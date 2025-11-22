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
    
    // MARK: - Sorting Tests
    
    func testSortsSongsByUpvoteCountHighestFirst() throws {
        let manager = MultipeerManager()
        
        // Create songs with different upvote counts
        let song1 = SongRequest(title: "Low Upvotes", artist: "Artist 1", requesterName: "user1")
        let song2 = SongRequest(title: "High Upvotes", artist: "Artist 2", requesterName: "user2")
        let song3 = SongRequest(title: "Medium Upvotes", artist: "Artist 3", requesterName: "user3")
        
        // Manually set upvote counts for testing
        var modifiedSong1 = song1
        modifiedSong1.upvoters = ["voter1"] // 1 upvote
        modifiedSong1.upvotes = modifiedSong1.upvoters.count
        
        var modifiedSong2 = song2
        modifiedSong2.upvoters = ["voter1", "voter2", "voter3"] // 3 upvotes
        modifiedSong2.upvotes = modifiedSong2.upvoters.count
        
        var modifiedSong3 = song3
        modifiedSong3.upvoters = ["voter1", "voter2"] // 2 upvotes
        modifiedSong3.upvotes = modifiedSong3.upvoters.count
        
        manager.receivedRequests = [modifiedSong1, modifiedSong2, modifiedSong3]
        
        // Test the sorting logic used in DJQueueView (use upvoters.count as source of truth)
        let sortedRequests = manager.receivedRequests.sorted { first, second in
            if first.upvoters.count != second.upvoters.count {
                return first.upvoters.count > second.upvoters.count // Highest upvotes first
            }
            return first.timestamp < second.timestamp // Oldest first as tiebreaker
        }
        
        XCTAssertEqual(sortedRequests.count, 3)
        XCTAssertEqual(sortedRequests[0].title, "High Upvotes", "Song with 3 upvotes should be first")
        XCTAssertEqual(sortedRequests[0].upvoters.count, 3)
        XCTAssertEqual(sortedRequests[1].title, "Medium Upvotes", "Song with 2 upvotes should be second")
        XCTAssertEqual(sortedRequests[1].upvoters.count, 2)
        XCTAssertEqual(sortedRequests[2].title, "Low Upvotes", "Song with 1 upvote should be last")
        XCTAssertEqual(sortedRequests[2].upvoters.count, 1)
    }
    
    func testSortsWithTiebreakingByTimestamp() throws {
        // Create two songs with same upvote count to test tiebreaker
        let earlierTime = Date().addingTimeInterval(-100) // 100 seconds ago
        let laterTime = Date() // now
        
        let olderSong = SongRequest(title: "Older Song", artist: "Artist 1", requesterName: "user1", timestamp: earlierTime)
        let newerSong = SongRequest(title: "Newer Song", artist: "Artist 2", requesterName: "user2", timestamp: laterTime)
        
        // Give both songs the same upvote count
        var modifiedOlderSong = olderSong
        modifiedOlderSong.upvoters = ["voter1", "voter2"] // 2 upvotes
        
        var modifiedNewerSong = newerSong
        modifiedNewerSong.upvoters = ["voter3", "voter4"] // 2 upvotes
        
        let requests = [modifiedNewerSong, modifiedOlderSong] // Add in reverse chronological order
        
        // Test the sorting logic
        let sortedRequests = requests.sorted { first, second in
            if first.upvotes != second.upvotes {
                return first.upvotes > second.upvotes
            }
            return first.timestamp < second.timestamp // Older requests first when upvotes are tied
        }
        
        XCTAssertEqual(sortedRequests.count, 2)
        XCTAssertEqual(sortedRequests[0].title, "Older Song", "Older song should come first when upvotes are tied")
        XCTAssertEqual(sortedRequests[1].title, "Newer Song", "Newer song should come second when upvotes are tied")
        XCTAssertEqual(sortedRequests[0].upvotes, sortedRequests[1].upvotes, "Both songs should have same upvote count")
    }
    
    func testSortsWithZeroUpvotes() throws {
        let manager = MultipeerManager()
        
        // Create songs with 0, 1, and 2 upvotes
        let noUpvotes = SongRequest(title: "No Upvotes", artist: "Artist 1", requesterName: "user1")
        let oneUpvote = SongRequest(title: "One Upvote", artist: "Artist 2", requesterName: "user2")
        let twoUpvotes = SongRequest(title: "Two Upvotes", artist: "Artist 3", requesterName: "user3")
        
        var modifiedOneUpvote = oneUpvote
        modifiedOneUpvote.upvoters = ["voter1"]
        modifiedOneUpvote.upvotes = modifiedOneUpvote.upvoters.count
        
        var modifiedTwoUpvotes = twoUpvotes
        modifiedTwoUpvotes.upvoters = ["voter1", "voter2"]
        modifiedTwoUpvotes.upvotes = modifiedTwoUpvotes.upvoters.count
        
        manager.receivedRequests = [noUpvotes, modifiedOneUpvote, modifiedTwoUpvotes]
        
        let sortedRequests = manager.receivedRequests.sorted { first, second in
            if first.upvoters.count != second.upvoters.count {
                return first.upvoters.count > second.upvoters.count
            }
            return first.timestamp < second.timestamp
        }
        
        XCTAssertEqual(sortedRequests[0].title, "Two Upvotes")
        XCTAssertEqual(sortedRequests[0].upvoters.count, 2)
        XCTAssertEqual(sortedRequests[1].title, "One Upvote")
        XCTAssertEqual(sortedRequests[1].upvoters.count, 1)
        XCTAssertEqual(sortedRequests[2].title, "No Upvotes")
        XCTAssertEqual(sortedRequests[2].upvoters.count, 0)
    }
    
    func testSortingWithSingleSong() throws {
        let manager = MultipeerManager()
        let singleSong = SongRequest(title: "Only Song", artist: "Only Artist", requesterName: "user1")
        manager.receivedRequests = [singleSong]
        
        let sortedRequests = manager.receivedRequests.sorted { first, second in
            if first.upvotes != second.upvotes {
                return first.upvotes > second.upvotes
            }
            return first.timestamp < second.timestamp
        }
        
        XCTAssertEqual(sortedRequests.count, 1)
        XCTAssertEqual(sortedRequests[0].title, "Only Song")
    }
    
    func testSortingWithEmptyQueue() throws {
        let manager = MultipeerManager()
        manager.receivedRequests = []
        
        let sortedRequests = manager.receivedRequests.sorted { first, second in
            if first.upvotes != second.upvotes {
                return first.upvotes > second.upvotes
            }
            return first.timestamp < second.timestamp
        }
        
        XCTAssertEqual(sortedRequests.count, 0)
    }
}
