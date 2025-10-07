//
//  WooWopApp.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI

@main
struct WooWopApp: App {
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var showingSetup = true
    
    var body: some Scene {
        WindowGroup {
            if showingSetup {
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