//
//  IconGenerator.swift
//  WooWop
//
//  Created on 11/25/25.
//

import UIKit

/// Utility to generate app icons from SF Symbols
struct IconGenerator {
    
    /// Generate app icon from waveform symbol
    static func generateWaveformIcon(size: CGFloat) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size * 0.6, weight: .bold)
        let waveformImage = UIImage(systemName: "waveform", withConfiguration: config)?
            .withTintColor(UIColor(red: 0.0, green: 0.941, blue: 1.0, alpha: 1.0), renderingMode: .alwaysOriginal)
        
        // Create background
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            // Black background
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // Draw waveform centered
            if let waveform = waveformImage {
                let imageRect = CGRect(
                    x: (size - waveform.size.width) / 2,
                    y: (size - waveform.size.height) / 2,
                    width: waveform.size.width,
                    height: waveform.size.height
                )
                waveform.draw(in: imageRect)
            }
        }
    }
    
    /// Generate all required app icon sizes
    static func generateAllAppIcons() {
        let sizes: [CGFloat] = [20, 29, 40, 58, 60, 76, 80, 87, 114, 120, 152, 167, 180, 1024]
        
        for size in sizes {
            if let icon = generateWaveformIcon(size: size) {
                // You can save these to Photos or Documents
                print("Generated icon for size: \(size)x\(size)")
            }
        }
    }
}