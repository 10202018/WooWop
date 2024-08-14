//
//  WooWopApp.swift
//  WooWop
//
//  Created by Jah Morris-Jones on 5/13/24.
//

import SwiftUI

@main
struct WooWopApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView(mediaLoader: RemoteMediaLoader(client: SHManagedSessionClient()))
        }
    }
}
