//
//  MultipeerManager.swift
//  WooWop
//
//  Created by AI Assistant on 10/6/25.
//

import Foundation
import MultipeerConnectivity
import Combine

class MultipeerManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedRequests: [SongRequest] = []
    @Published var isDJ = false
    @Published var hasJoinedSession = false
    
    // MARK: - Multipeer Connectivity Properties
    private let serviceType = "woowop-requests"
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    
    // MARK: - User Properties
    @Published var userName: String = UIDevice.current.name
    
    override init() {
        self.session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }
    
    // MARK: - Public Methods
    func startHosting() {
        isDJ = true
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func joinSession() {
        isDJ = false
        hasJoinedSession = true
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stopSession() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        isDJ = false
        isConnected = false
        hasJoinedSession = false
        connectedPeers.removeAll()
    }
    
    func sendSongRequest(_ request: SongRequest) {
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to send request to")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(request)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Sent song request: \(request.title) by \(request.artist)")
        } catch {
            print("Failed to send song request: \(error)")
        }
    }
    
    func removeSongRequest(_ request: SongRequest) {
        receivedRequests.removeAll { $0.id == request.id }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeers.append(peerID)
                self.isConnected = true
                print("Connected to: \(peerID.displayName)")
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.isConnected = !self.connectedPeers.isEmpty
                print("Disconnected from: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let request = try JSONDecoder().decode(SongRequest.self, from: data)
            DispatchQueue.main.async {
                self.receivedRequests.append(request)
                print("Received song request: \(request.title) by \(request.artist) from \(request.requesterName)")
            }
        } catch {
            print("Failed to decode song request: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations when hosting as DJ
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Auto-invite when found peer (DJ)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
