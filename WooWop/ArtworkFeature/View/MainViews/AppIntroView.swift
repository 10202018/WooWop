//
//  AppIntroView.swift
//  WooWop
//
//  Created on 11/25/25.
//

import SwiftUI

/// App intro screen with animated waveform that zooms in like Netflix intro
/// 
/// This view displays a large animated waveform with the WooWop branding
/// and performs a zoom-in animation that transitions into the main app.
/// The animation creates a dramatic entrance effect similar to Netflix's intro.
struct AppIntroView: View {
    /// Callback to trigger when intro animation completes
    let onComplete: () -> Void
    
    /// Animation state for waveform scaling effect
    @State private var waveformScale: CGFloat = 1.0
    @State private var waveformOpacity: Double = 1.0
    
    /// Animation state for zoom effect
    @State private var zoomScale: CGFloat = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var whiteOverlayOpacity: Double = 0.0
    
    /// Controls the intro sequence timing
    @State private var showingZoom = false
    @State private var fadeToBlack = false
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .opacity(fadeToBlack ? 1.0 : backgroundOpacity)
            
            VStack(spacing: 30) {
                // Main waveform logo
                Image(systemName: "waveform")
                    .font(.system(size: 120))
                    .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                    .shadow(color: .cyan, radius: 20)
                    .scaleEffect(waveformScale * zoomScale)
                    .opacity(waveformOpacity)
                
                VStack(spacing: 8) {
                    // App name
                    Text("WooWop")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .opacity(showingZoom ? 0 : 1)
                        .scaleEffect(showingZoom ? 0.5 : 1.0)
                    
                    // Credit text
                    Text("By X, The Turntablist")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .cyan, radius: 8)
                        .shadow(color: .cyan.opacity(0.6), radius: 4)
                        .opacity(showingZoom ? 0 : 1)
                        .scaleEffect(showingZoom ? 0.5 : 1.0)
                }
            }
            
            // White overlay for smooth fade transition
            Color.white
                .ignoresSafeArea()
                .opacity(whiteOverlayOpacity)
        }
        .onAppear {
            startIntroAnimation()
        }
    }
    
    /// Starts the intro animation sequence
    private func startIntroAnimation() {
        // Phase 1: Initial waveform pulsing (2 seconds)
        withAnimation(Animation.easeInOut(duration: 1.0).repeatCount(3, autoreverses: true)) {
            waveformScale = 1.15
        }
        
        withAnimation(Animation.easeInOut(duration: 1.2).repeatCount(3, autoreverses: true)) {
            waveformOpacity = 0.8
        }
        
        // Phase 2: Start zoom effect after initial pulsing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingZoom = true
            
            // Hide text first
            withAnimation(.easeInOut(duration: 0.5)) {
                // Text fades and scales down
            }
            
            // Then start dramatic zoom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 1.5)) {
                    zoomScale = 15.0 // Zoom way in
                    waveformOpacity = 0.0
                }
                
                // Start white fade when zoom reaches peak
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        whiteOverlayOpacity = 1.0
                    }
                }
            }
        }
        
        // Phase 3: Fade to black and complete transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                whiteOverlayOpacity = 0.0
            }
            
            // Complete transition after white fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

#Preview {
    AppIntroView {
        print("Intro completed")
    }
}
