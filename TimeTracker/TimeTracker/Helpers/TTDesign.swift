//
//  TTDesign.swift
//  TimeTracker
//
//  设计系统规范 Token (对应 DESIGN_SPEC.md v1.3)
//

import SwiftUI

enum TTDesign {
    
    // MARK: Colors - Semantic
    enum SemanticColor {
        static let output      = Color(hex: "#00C853")  // Deep Action
        static let input       = Color(hex: "#2979FF")  // Ocean Intake
        static let maintenance = Color(hex: "#9E9E9E")  // Neutral Ground
        static let consumption = Color(hex: "#FF1744")  // Black Hole
    }
    
    // MARK: Colors - Status
    enum StatusColor {
        static let success = Color(hex: "#34C759")
        static let warning = Color(hex: "#FF9500")
        static let danger  = Color(hex: "#FF3B30")
        static let info    = Color(hex: "#007AFF")
    }
    
    // MARK: Typography
    enum Typography {
        static let display  = Font.system(size: 32, weight: .bold, design: .monospaced)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let title    = Font.system(size: 16, weight: .semibold)
        static let body     = Font.system(size: 14, weight: .medium)
        static let caption  = Font.system(size: 12, weight: .regular)
        static let micro    = Font.system(size: 10, weight: .regular)
        
        static let score    = Font.system(size: 48, weight: .heavy, design: .monospaced)
        static let timer    = Font.system(size: 40, weight: .bold, design: .monospaced)
        static let duration = Font.system(size: 14, weight: .medium, design: .monospaced)
    }
    
    // MARK: Spacing
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: Radius
    enum Radius {
        static let small:  CGFloat = 4
        static let medium: CGFloat = 8
        static let card:   CGFloat = 12
        static let button: CGFloat = 16
    }
}

// MARK: - Hex Color Extension
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
