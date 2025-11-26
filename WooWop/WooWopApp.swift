//
//  WooWopApp.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI

/// The main entry point for the WooWop application.
/// 
/// WooWop is a social music discovery app that allows users to identify songs using Shazam
/// and request them to a DJ in real-time using peer-to-peer networking. The app supports
/// two main roles: DJ (host) and Listener (client).
@main
struct WooWopApp: App {
    /// Manages peer-to-peer connectivity and song requests between devices
    @StateObject private var multipeerManager = MultipeerManager()
    
    /// Controls whether to show the initial setup screen or the main content
    @State private var showingSetup = true
    
    /// Controls whether to show the intro animation
    @State private var showingIntro = true
    
    var body: some Scene {
        WindowGroup {
            if showingIntro {
                AppIntroView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingIntro = false
                    }
                }
            } else if showingSetup {
                ConnectionSetupView(multipeerManager: multipeerManager)
                    .onChange(of: multipeerManager.isDJ) { isDJ in
                        if isDJ {
                            showingSetup = false
                        }
                    }
                    .onChange(of: multipeerManager.hasJoinedSession) { hasJoined in
                        if hasJoined {
                            showingSetup = false
                        }
                    }
            } else {
                ContentView(mediaLoader: RemoteMediaLoader(client: SHManagedSessionClient()))
                    .environmentObject(multipeerManager)
            }
        }
    }
}