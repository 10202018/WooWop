//
//  MultipeerManager.swift
//  WooWop
//
//  Created by AI Assistant on 10/6/25.
//

import Foundation
import MultipeerConnectivity
import Combine

/// Manages peer-to-peer connectivity and communication for song requests.
/// 
/// This class handles the entire multipeer connectivity lifecycle, allowing devices
/// to discover each other, establish connections, and exchange song request data
/// without requiring a backend server. It supports both DJ (host) and Listener (client) modes.
class MultipeerManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Indicates whether this device is currently connected to other peers
    @Published var isConnected = false
    
    /// Array of currently connected peer devices
    @Published var connectedPeers: [MCPeerID] = []
    
    /// Array of song requests received from other devices (DJ mode)
    @Published var receivedRequests: [SongRequest] = []
    
    /// Indicates whether this device is operating in DJ mode (hosting)
    @Published var isDJ = false
    
    /// Indicates whether this device has joined a session as a listener
    @Published var hasJoinedSession = false
    
    // MARK: - Multipeer Connectivity Properties
    
    /// The service type identifier for this app's multipeer sessions
    private let serviceType = "woowop-requests"
    
    /// Unique identifier for this device in the multipeer session
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    /// Advertiser for broadcasting this device's availability (DJ mode)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    /// Browser for discovering nearby DJ devices (Listener mode)
    private let serviceBrowser: MCNearbyServiceBrowser
    
    /// The multipeer connectivity session managing all connections
    private let session: MCSession
    
    // MARK: - User Properties
    
    /// The display name for this user in song requests
    @Published var userName: String = UIDevice.current.name
    
    /// Initializes the MultipeerManager with default settings.
    /// 
    /// Sets up the multipeer connectivity components including the session,
    /// advertiser, and browser with appropriate delegates.
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
    
    /// Starts hosting a session as a DJ.
    /// 
    /// When called, this device begins advertising itself as available for connections
    /// and switches to DJ mode to receive song requests from listeners.
    func startHosting() {
        isDJ = true
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    /// Joins an existing session as a listener.
    /// 
    /// When called, this device begins searching for nearby DJs and attempts
    /// to connect to them for sending song requests.
    func joinSession() {
        isDJ = false
        hasJoinedSession = true
        serviceBrowser.startBrowsingForPeers()
    }
    
    /// Stops all multipeer connectivity activities.
    /// 
    /// Disconnects from all peers, stops advertising/browsing, and resets
    /// the manager to its initial state.
    func stopSession() {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        isDJ = false
        isConnected = false
        hasJoinedSession = false
        connectedPeers.removeAll()
    }
    
    /// Sends a song request to all connected peers.
    /// 
    /// Encodes the song request as JSON and transmits it to all connected devices.
    /// Typically used by listeners to send requests to the DJ.
    /// 
    /// - Parameter request: The song request to send
    func sendSongRequest(_ request: SongRequest) {
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to send request to")
            return
        }

        let wrapper = QueueMessage.songRequest(request)
        do {
            let data = try JSONEncoder().encode(wrapper)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Sent wrapped song request: \(request.title) by \(request.artist)")
        } catch {
            print("Failed to send wrapped song request: \(error)")
        }
    }
    
    /// Removes a song request from the received requests list.
    /// 
    /// Typically used by DJs to mark requests as completed or dismissed.
    /// 
    /// - Parameter request: The song request to remove
    func removeSongRequest(_ request: SongRequest) {
        receivedRequests.removeAll { $0.id == request.id }
    }

    // MARK: - Message Protocol

    /// Wrapper enum used on the wire to identify the payload type.
    enum QueueMessage: Codable {
        case songRequest(SongRequest)
        case queue([SongRequest])
        case request

        private enum CodingKeys: String, CodingKey {
            case type
            case payload
        }

        private enum MessageType: String, Codable {
            case songRequest
            case queue
            case request
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(MessageType.self, forKey: .type)
            switch type {
            case .songRequest:
                let req = try container.decode(SongRequest.self, forKey: .payload)
                self = .songRequest(req)
            case .queue:
                let q = try container.decode([SongRequest].self, forKey: .payload)
                self = .queue(q)
            case .request:
                self = .request
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .songRequest(let req):
                try container.encode(MessageType.songRequest, forKey: .type)
                try container.encode(req, forKey: .payload)
            case .queue(let q):
                try container.encode(MessageType.queue, forKey: .type)
                try container.encode(q, forKey: .payload)
            case .request:
                try container.encode(MessageType.request, forKey: .type)
            }
        }
    }

    /// Sends the DJ's current queue to connected peers.
    func broadcastQueue() {
        guard !session.connectedPeers.isEmpty else { return }
        let wrapper = QueueMessage.queue(receivedRequests)
        do {
            let data = try JSONEncoder().encode(wrapper)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Broadcasted queue to peers (\(receivedRequests.count) items)")
        } catch {
            print("Failed to broadcast queue: \(error)")
        }
    }

    /// Requests the current DJ queue from connected peers.
    func requestQueue() {
        // Do nothing if we're the DJ or there are no peers
        guard !isDJ else { return }
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to request queue from")
            return
        }

        let wrapper = QueueMessage.request
        do {
            let data = try JSONEncoder().encode(wrapper)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Requested queue from peers")
        } catch {
            print("Failed to request queue: \(error)")
        }
    }

    /// Simple retry sender: attempts to send data several times with a short delay.
    func sendDataWithRetry(_ data: Data, to peers: [MCPeerID], attempts: Int = 3, delayMs: UInt64 = 200) {
        guard !peers.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            var remaining = attempts
            while remaining > 0 {
                do {
                    try self.session.send(data, toPeers: peers, with: .reliable)
                    print("sendDataWithRetry: sent data to peers")
                    return
                } catch {
                    remaining -= 1
                    if remaining == 0 {
                        print("sendDataWithRetry: final failure: \(error)")
                        return
                    }
                    let ns = delayMs * 1_000_000
                    usleep(useconds_t(ns / 1_000_000))
                }
            }
        }
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
        // Try to decode our wrapper QueueMessage first
        do {
            let wrapper = try JSONDecoder().decode(QueueMessage.self, from: data)
            DispatchQueue.main.async {
                switch wrapper {
                case .songRequest(let req):
                    // DJs should accept song requests
                    self.receivedRequests.append(req)
                    print("Received song request: \(req.title) by \(req.artist) from \(req.requesterName)")
                case .queue(let queue):
                    // Listeners receive the full queue
                    self.receivedRequests = queue
                    print("Received queue with \(queue.count) items from \(peerID.displayName)")
                case .request:
                    // Peer asked for the queue; if we're DJ, respond
                    if self.isDJ {
                        self.broadcastQueue()
                    }
                }
            }
        } catch {
            // Fallback: try decoding a raw SongRequest for compatibility
            do {
                let request = try JSONDecoder().decode(SongRequest.self, from: data)
                DispatchQueue.main.async {
                    self.receivedRequests.append(request)
                    print("Received legacy song request: \(request.title) by \(request.artist) from \(request.requesterName)")
                }
            } catch {
                print("Failed to decode incoming data: \(error)")
            }
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
