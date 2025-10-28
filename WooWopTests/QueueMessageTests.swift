import XCTest
@testable import WooWop

final class QueueMessageTests: XCTestCase {

    func testSongRequestRoundtrip() throws {
        let req = SongRequest(title: "Test Title", artist: "Test Artist", requesterName: "Tester", shazamID: "shz-1")
        let wrapper = MultipeerManager.QueueMessage.songRequest(req)
        let data = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(MultipeerManager.QueueMessage.self, from: data)

        switch decoded {
        case .songRequest(let r):
            XCTAssertEqual(r.title, req.title)
            XCTAssertEqual(r.artist, req.artist)
            XCTAssertEqual(r.requesterName, req.requesterName)
        default:
            XCTFail("Decoded wrong QueueMessage case")
        }
    }

    func testQueueRoundtrip() throws {
        let r1 = SongRequest(title: "T1", artist: "A1", requesterName: "R1")
        let r2 = SongRequest(title: "T2", artist: "A2", requesterName: "R2")
        let wrapper = MultipeerManager.QueueMessage.queue([r1, r2])
        let data = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(MultipeerManager.QueueMessage.self, from: data)

        switch decoded {
        case .queue(let arr):
            XCTAssertEqual(arr.count, 2)
            XCTAssertEqual(arr[0].title, "T1")
            XCTAssertEqual(arr[1].title, "T2")
        default:
            XCTFail("Decoded wrong QueueMessage case")
        }
    }

    func testLegacySongRequestDecode() throws {
        // Ensure a raw SongRequest still encodes/decodes correctly (compatibility)
        let req = SongRequest(title: "Legacy", artist: "Legacy Artist", requesterName: "LegacyUser")
        let data = try JSONEncoder().encode(req)
        let decoded = try JSONDecoder().decode(SongRequest.self, from: data)
        XCTAssertEqual(decoded.title, req.title)
        XCTAssertEqual(decoded.requesterName, req.requesterName)
    }
}
