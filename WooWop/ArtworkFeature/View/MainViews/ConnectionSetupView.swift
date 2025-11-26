//
//  ConnectionSetupView.swift
//  WooWop
//
//  Created by Theron Jones on 10/6/25.
//

import SwiftUI

/// Initial setup interface for choosing user role and configuring connectivity.
/// 
/// This view serves as the onboarding screen where users select their role
/// (DJ or Listener), set their display name, and initiate the appropriate
/// multipeer connectivity mode. It provides real-time feedback on connection status.
struct ConnectionSetupView: View {
    /// Manager handling multipeer connectivity setup and status
    @ObservedObject var multipeerManager: MultipeerManager
    
    /// User's display name for song requests and session identification
    @State private var userName: String = ""
    
    /// Animation state for waveform pulsing effect
    @State private var waveformScale: CGFloat = 1.0
    @State private var waveformOpacity: Double = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Tech Noir background with Technical Grid
                ZStack {
                    // 1. The Base: Pure Black
                    Color.black.ignoresSafeArea()
                    
                    // 2. The Spotlight: A deep, cold Radial Gradient
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.067, green: 0.094, blue: 0.153), // Dark Navy/Grey center
                            Color.black                                    // Fades to pure black edges
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                    
                    // 3. The Technical Grid Layer
                    Canvas { context, size in
                        let gridSize: CGFloat = 40
                        let lineWidth: CGFloat = 0.5
                        let gridColor = Color(red: 0.0, green: 0.941, blue: 1.0) // Neon Cyan
                        let opacity: Double = 0.08
                        
                        let width = size.width
                        let height = size.height
                        
                        // Draw Vertical Lines
                        for x in stride(from: 0, to: width, by: gridSize) {
                            let path = Path { p in
                                p.move(to: CGPoint(x: x, y: 0))
                                p.addLine(to: CGPoint(x: x, y: height))
                            }
                            context.stroke(path, with: .color(gridColor.opacity(opacity)), lineWidth: lineWidth)
                        }
                        
                        // Draw Horizontal Lines
                        for y in stride(from: 0, to: height, by: gridSize) {
                            let path = Path { p in
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: width, y: y))
                            }
                            context.stroke(path, with: .color(gridColor.opacity(opacity)), lineWidth: lineWidth)
                        }
                    }
                    .ignoresSafeArea()
                    .mask {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0),      // Visible in center
                                .init(color: .black.opacity(0.6), location: 0.6),
                                .init(color: .clear, location: 1)       // Fades out at edges
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 500
                        )
                        .ignoresSafeArea()
                    }
                    
                    // 4. The Digital Grain Texture
                    GeometryReader { proxy in
                        Canvas { context, size in
                            let noiseLevel: Double = 0.995 // Higher = Less Noise
                            
                            for _ in 0..<Int(size.width * size.height / 100) {
                                let x = Double.random(in: 0...size.width)
                                let y = Double.random(in: 0...size.height)
                                if Double.random(in: 0...1) > noiseLevel {
                                    let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                                    context.fill(Path(rect), with: .color(.white.opacity(0.05)))
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .drawingGroup()
                    
                    // 5. Subtle Blue Glow for atmosphere
                    RadialGradient(
                        colors: [
                            Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.05), // Faint Cyan center
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 24) {
                    // Header with cyberpunk styling
                    VStack(spacing: 16) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                            .shadow(color: .cyan, radius: 10)
                            .scaleEffect(waveformScale)
                            .opacity(waveformOpacity)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                    waveformScale = 1.2
                                }
                                withAnimation(Animation.easeInOut(duration: 3.33).repeatForever(autoreverses: true)) {
                                    waveformOpacity = 0.7
                                }
                            }
                        
                        Text("WooWop")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white) // Pure white
                        
                        Text("Request songs to the DJ or become the DJ yourself!")
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.7)) // Dimmed white
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                
                // User Name Input with cyberpunk styling
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                        .foregroundColor(Color.white) // Pure white
                    
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.plain)
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.6)) // Surface card
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3), // Electric blue border
                                            lineWidth: 1
                                        )
                                )
                        )
                        .onSubmit {
                            multipeerManager.userName = userName
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Mode Selection with cyberpunk styling
                VStack(spacing: 16) {
                    Text("Choose your role:")
                        .font(.headline)
                        .foregroundColor(Color.white) // Pure white
                    
                    VStack(spacing: 12) {
                        // Join as Listener button
                        Button {
                            multipeerManager.userName = userName.isEmpty ? UIDevice.current.name : userName
                            multipeerManager.joinSession()
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                                Text("Join as Listener")
                                    .foregroundColor(Color.white)
                                Spacer()
                                Text("Request songs")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.6)) // Surface card
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3), // Electric blue border
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(
                                color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.1),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        
                        // Become DJ button should be available only if not already connected to a DJ
                        if !multipeerManager.isConnected || multipeerManager.isDJ {
                            Button {
                                multipeerManager.userName = userName.isEmpty ? UIDevice.current.name : userName
                                multipeerManager.startHosting()
                            } label: {
                                HStack {
                                    Image(systemName: "music.mic")
                                        .foregroundColor(Color.white)
                                    Text("Become DJ")
                                        .font(.system(.body, design: .default, weight: .bold))
                                        .textCase(.uppercase)
                                        .foregroundColor(Color.white)
                                    Spacer()
                                    Text("Receive requests")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.8))
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 1.0, green: 0.0, blue: 0.6)) // Electric pink
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(
                                    color: Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.6),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            }
                        } else {
                            // When a DJ is present, show a read-only view explaining the role
                            HStack {
                                Image(systemName: "music.mic")
                                    .foregroundColor(Color.gray)
                                Text("DJ unavailable")
                                    .foregroundColor(Color.gray)
                                Spacer()
                                Text("View DJ queue")
                                    .font(.caption)
                                    .foregroundColor(Color.gray.opacity(0.7))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.3)) // Darker surface
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .onTapGesture {
                                // Let listeners still view the DJ queue
                                multipeerManager.hasJoinedSession = true
                                multipeerManager.joinSession()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connection Status with cyberpunk styling
                if multipeerManager.isConnected || multipeerManager.isDJ || multipeerManager.hasJoinedSession {
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(multipeerManager.isConnected || multipeerManager.isDJ ? 
                                      Color(red: 0.0, green: 0.941, blue: 1.0) : // Electric blue when connected
                                      Color(red: 1.0, green: 0.0, blue: 0.6)) // Electric pink when searching
                                .frame(width: 8, height: 8)
                                .shadow(
                                    color: multipeerManager.isConnected || multipeerManager.isDJ ? 
                                            Color(red: 0.0, green: 0.941, blue: 1.0) : 
                                            Color(red: 1.0, green: 0.0, blue: 0.6),
                                    radius: 4
                                )
                            
                            Text(getConnectionStatusText())
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                        
                        if multipeerManager.hasJoinedSession && !multipeerManager.isConnected && !multipeerManager.isDJ {
                            Text("Searching for DJ...")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.4)) // Surface card
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .ignoresSafeArea(.all)
    }
    
    /// Generates appropriate status text based on current connection state.
    /// 
    /// This helper method provides user-friendly status messages that reflect
    /// the current state of the multipeer connectivity session.
    /// 
    /// - Returns: Localized status string describing the current connection state
    private func getConnectionStatusText() -> String {
        if multipeerManager.isDJ {
            return "DJ Mode Active"
        } else if multipeerManager.isConnected {
            return "Connected to DJ"
        } else if multipeerManager.hasJoinedSession {
            return "Looking for DJ"
        } else {
            return "Ready to connect"
        }
    }
}

#Preview {
    ConnectionSetupView(multipeerManager: MultipeerManager())
}
