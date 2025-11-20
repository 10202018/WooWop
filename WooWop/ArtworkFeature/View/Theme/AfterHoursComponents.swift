//
//  AfterHoursComponents.swift
//  WooWop
//
//  Created by Theron Jones on 11/19/25.
//

import SwiftUI

// MARK: - After Hours Color Palette

extension Color {
    /// After Hours Cyberpunk Theme Colors
    struct AfterHours {
        /// Midnight background colors
        static let deepMidnight = Color(hex: "0F0C29")
        static let darkPurpleBlack = Color(hex: "1A1A2E")
        
        /// Primary action color (Electric Pink)
        static let electricPink = Color(hex: "FF0099")
        
        /// Secondary accent color (Cyan)
        static let electricBlue = Color(hex: "00F0FF")
        
        /// Surface colors
        static let darkBlueGrey = Color(hex: "16213E")
        static let surfaceCard = Color(hex: "16213E").opacity(0.6)
        
        /// Text colors
        static let pureWhite = Color(hex: "FFFFFF")
        static let softRed = Color(hex: "E94560")
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - After Hours Gradients

extension LinearGradient {
    /// Midnight background gradient
    static let afterHoursBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color.AfterHours.deepMidnight,
            Color.AfterHours.darkPurpleBlack
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension RadialGradient {
    /// Club light radial effect
    static func clubLightEffect(center: UnitPoint = .topLeading) -> RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.AfterHours.electricPink.opacity(0.1),
                Color.AfterHours.deepMidnight.opacity(0.3),
                Color.AfterHours.darkPurpleBlack
            ]),
            center: center,
            startRadius: 50,
            endRadius: 400
        )
    }
}

// MARK: - After Hours Background View

struct AfterHoursBackground: View {
    // Configuration
    let gridSize: CGFloat = 40     // Distance between lines
    let lineWidth: CGFloat = 0.5   // Ultra-thin for that "Retina" look
    let gridColor: Color = Color(hex: "00F0FF") // Your Neon Cyan
    let opacity: Double = 0.08     // Very subtle (Data texture, not content)
    
    var body: some View {
        ZStack {
            // 1. The Base: Pure Black
            Color.black.ignoresSafeArea()
            
            // 2. The Spotlight: A deep, cold Radial Gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "111827"), // Dark Navy/Grey center
                    Color.black           // Fades to pure black edges
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // 3. The Technical Grid Layer
            Canvas { context, size in
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
            
            // 4. Digital Grain Texture
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
            
            // 5. Subtle Blue Glow in center for atmosphere
            RadialGradient(
                colors: [
                    Color(hex: "00F0FF").opacity(0.05), // Faint Cyan center
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Neon Glow Button Style

struct NeonGlowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title2, design: .default, weight: .bold))
            .textCase(.uppercase)
            .foregroundColor(Color.AfterHours.pureWhite)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.AfterHours.electricPink)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.AfterHours.pureWhite.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.AfterHours.electricPink.opacity(0.6),
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style (for destructive actions)

struct GhostButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = Color.AfterHours.softRed) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .semibold))
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(configuration.isPressed ? 0.1 : 0))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Icon Button Style (for toolbar icons with better contrast)

struct EnhancedIconButtonStyle: ButtonStyle {
    let iconColor: Color
    let backgroundColor: Color
    
    init(iconColor: Color = Color.AfterHours.electricBlue, backgroundColor: Color = Color.black.opacity(0.3)) {
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(iconColor)
            .padding(8)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .strokeBorder(iconColor.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(
                color: iconColor.opacity(0.2),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Cyberpunk Status Pill

struct CyberStatusPill: View {
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.AfterHours.electricBlue : Color.gray)
                .frame(width: 8, height: 8)
                .shadow(
                    color: isActive ? Color.AfterHours.electricBlue : Color.clear,
                    radius: 4
                )
            
            Text(text)
                .font(.caption.weight(.medium))
                .textCase(.uppercase)
                .foregroundColor(isActive ? Color.AfterHours.electricBlue : Color.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.AfterHours.darkBlueGrey.opacity(0.7))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isActive ? Color.AfterHours.electricBlue.opacity(0.5) : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isActive ? Color.AfterHours.electricBlue.opacity(0.2) : Color.clear,
            radius: 8
        )
    }
}

// MARK: - Cyberpunk Card Modifier

struct CyberCardModifier: ViewModifier {
    let glowColor: Color
    
    init(glowColor: Color = Color.AfterHours.electricBlue) {
        self.glowColor = glowColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.AfterHours.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        glowColor.opacity(0.3),
                                        glowColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: glowColor.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func cyberCard(glowColor: Color = Color.AfterHours.electricBlue) -> some View {
        modifier(CyberCardModifier(glowColor: glowColor))
    }
    
    /// Adds enhanced contrast background to icons for better visibility
    func enhancedIcon(
        color: Color = Color.AfterHours.electricBlue, 
        backgroundColor: Color = Color.black.opacity(0.3)
    ) -> some View {
        self
            .foregroundColor(color)
            .padding(8)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .strokeBorder(color.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(
                color: color.opacity(0.2),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Ultra Thin Navigation Bar

struct UltraNavBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
        #if os(iOS)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }
}

extension View {
    func ultraThinNavBar() -> some View {
        modifier(UltraNavBarModifier())
    }
}

// MARK: - Preview

#if DEBUG
struct AfterHoursComponents_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZStack {
                AfterHoursBackground()
                
                VStack(spacing: 24) {
                    CyberStatusPill(text: "DJ Mode Active", isActive: true)
                    
                    Button("Start DJ Mode") {
                        // Action
                    }
                    .buttonStyle(NeonGlowButtonStyle())
                    
                    Button("Stop DJ Mode") {
                        // Action
                    }
                    .buttonStyle(GhostButtonStyle())
                    
                    VStack {
                        Text("Sample Content")
                            .foregroundColor(Color.AfterHours.pureWhite)
                        Text("In a cyber card")
                            .foregroundColor(Color.AfterHours.pureWhite.opacity(0.7))
                    }
                    .padding()
                    .cyberCard()
                }
                .padding()
            }
            .navigationTitle("After Hours")
            .ultraThinNavBar()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
