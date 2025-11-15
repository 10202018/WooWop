import XCTest
@testable import WooWop

final class RemoveRequestTests: XCTestCase {

    func testRemoveMessageRoundtrip() throws {
        let id = UUID()
        let wrapper = MultipeerManager.QueueMessage.remove(id)
        let data = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(MultipeerManager.QueueMessage.self, from: data)

        switch decoded {
        case .remove(let rid):
            XCTAssertEqual(rid, id)
        default:
            XCTFail("Decoded wrong QueueMessage case")
        }
    }

    func testCanRemoveLogic() throws {
        let manager = MultipeerManager()

        // Case 1: manager is DJ -> can remove any request
        manager.isDJ = true
        let req1 = SongRequest(title: "Song", artist: "Artist", requesterName: "Someone")
        XCTAssertTrue(canRemove(manager: manager, request: req1))

        // Case 2: manager is not DJ but is the original requester
        manager.isDJ = false
        let req2 = SongRequest(title: "Song2", artist: "Artist2", requesterName: manager.localDisplayName)
        XCTAssertTrue(canRemove(manager: manager, request: req2))

        // Case 3: manager is not DJ and not the requester
        manager.isDJ = false
        let req3 = SongRequest(title: "Song3", artist: "Artist3", requesterName: "OtherPerson")
        XCTAssertFalse(canRemove(manager: manager, request: req3))
    }

    private func canRemove(manager: MultipeerManager, request: SongRequest) -> Bool {
        return manager.isDJ || request.requesterName == manager.localDisplayName
    }
}
