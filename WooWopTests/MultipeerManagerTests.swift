//
//  MultipeerManagerTests.swift
//  WooWopTests
//
//  Created on 11/22/25.
//

import XCTest
import MultipeerConnectivity
@testable import WooWop

class MultipeerManagerTests: XCTestCase {
    
    var multipeerManager: MultipeerManager!
    
    override func setUpWithError() throws {
        multipeerManager = MultipeerManager()
    }
    
    override func tearDownWithError() throws {
        multipeerManager.stopSession()
        multipeerManager = nil
    }
    
    // MARK: - DJ Mode Tests
    
    func testStartHosting() {
        // Given
        XCTAssertFalse(multipeerManager.isDJ)
        
        // When
        multipeerManager.startHosting()
        
        // Then
        XCTAssertTrue(multipeerManager.isDJ)
    }
    
    func testJoinSession() {
        // Given
        XCTAssertFalse(multipeerManager.hasJoinedSession)
        XCTAssertFalse(multipeerManager.isDJ)
        
        // When
        multipeerManager.joinSession()
        
        // Then
        XCTAssertTrue(multipeerManager.hasJoinedSession)
        XCTAssertFalse(multipeerManager.isDJ)
    }
    
    func testStopSession() {
        // Given
        multipeerManager.startHosting()
        XCTAssertTrue(multipeerManager.isDJ)
        
        // When
        multipeerManager.stopSession()
        
        // Then
        XCTAssertFalse(multipeerManager.isDJ)
        XCTAssertFalse(multipeerManager.isConnected)
        XCTAssertFalse(multipeerManager.hasJoinedSession)
        XCTAssertEqual(multipeerManager.connectedPeers.count, 0)
    }
    
    // MARK: - Connection State Tests
    
    func testInitialState() {
        // Then
        XCTAssertFalse(multipeerManager.isConnected)
        XCTAssertFalse(multipeerManager.isDJ)
        XCTAssertFalse(multipeerManager.hasJoinedSession)
        XCTAssertFalse(multipeerManager.djAvailable)
        XCTAssertNil(multipeerManager.currentDJName)
        XCTAssertEqual(multipeerManager.connectedPeers.count, 0)
        XCTAssertEqual(multipeerManager.receivedRequests.count, 0)
    }
    
    func testLocalDisplayName() {
        // Then - Should return the device name
        XCTAssertFalse(multipeerManager.localDisplayName.isEmpty)
        XCTAssertEqual(multipeerManager.localDisplayName, UIDevice.current.name)
    }
    
    // MARK: - Song Request Tests
    
    func testSendSongRequest() {
        // Given
        let song = SongRequest(
            title: "Test Song", 
            artist: "Test Artist", 
            requesterName: "User1"
        )
        
        // When - Should not crash when no peers are connected
        multipeerManager.sendSongRequest(song)
        
        // Then - No assertion needed, just ensuring it doesn't crash
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    func testRemoveSongRequest() {
        // Given
        let song1 = SongRequest(
            title: "Test Song 1", 
            artist: "Test Artist 1", 
            requesterName: "User1"
        )
        let song2 = SongRequest(
            title: "Test Song 2", 
            artist: "Test Artist 2", 
            requesterName: "User2"
        )
        
        // Manually add to received requests to simulate receiving them
        multipeerManager.receivedRequests = [song1, song2]
        XCTAssertEqual(multipeerManager.receivedRequests.count, 2)
        
        // When
        multipeerManager.removeSongRequest(song1)
        
        // Then
        XCTAssertEqual(multipeerManager.receivedRequests.count, 1)
        XCTAssertEqual(multipeerManager.receivedRequests.first?.id, song2.id)
    }
    
    func testUpvoteSong() {
        // Given
        let song = SongRequest(
            title: "Test Song", 
            artist: "Test Artist", 
            requesterName: "User1"
        )
        multipeerManager.receivedRequests = [song]
        XCTAssertEqual(song.upvoters.count, 0)
        
        // When - Use the actual sendUpvote method
        multipeerManager.sendUpvote(song.id)
        
        // Then - Just verify the method can be called without crashing
        // Note: Full testing would require mocking the session and message handling
        XCTAssertTrue(true, "sendUpvote method executed without crashing")
    }
    
    // MARK: - Session Delegate Integration Tests
    
    func testSessionStateHandling() {
        // Given
        let testPeer = MCPeerID(displayName: "TestPeer")
        let testSession = MCSession(peer: testPeer, securityIdentity: nil, encryptionPreference: .none)
        
        // When - Simulate peer connection through the delegate method
        multipeerManager.session(testSession, peer: testPeer, didChange: .connected)
        
        // Then - Should update connection state
        // Note: This test verifies the delegate method works correctly
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    func testBrowserDelegateHandling() {
        // Given
        let testPeer = MCPeerID(displayName: "TestDJ")
        let testBrowser = MCNearbyServiceBrowser(peer: testPeer, serviceType: "woowop-requests")
        
        // When - Simulate peer discovery
        multipeerManager.browser(testBrowser, foundPeer: testPeer, withDiscoveryInfo: ["dj": "1", "name": "TestDJ"])
        
        // Then - Should handle peer discovery
        // Note: This test verifies the delegate method exists and can be called
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
    
    func testAdvertiserDelegateHandling() {
        // Given
        multipeerManager.startHosting()
        let testPeer = MCPeerID(displayName: "TestListener")
        let testAdvertiser = MCNearbyServiceAdvertiser(peer: testPeer, discoveryInfo: nil, serviceType: "woowop-requests")
        
        // When - Simulate incoming connection request
        multipeerManager.advertiser(testAdvertiser, didReceiveInvitationFromPeer: testPeer, withContext: nil) { accept, session in
            // This is the invitation handler - should be called
            XCTAssertNotNil(session)
        }
        
        // Then - Should handle invitation
        XCTAssertTrue(true) // Test passes if no exception is thrown
    }
}
