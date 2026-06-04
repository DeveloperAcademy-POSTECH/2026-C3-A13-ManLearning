
//
//  Color+Tokens.swift
//  DoUnlock
//

import SwiftUI

extension Color {
    static let screenBackground = Color(hex: 0xF1EFEF)
    static let headingText      = Color(hex: 0x0F172A)
    static let secondaryText    = Color(hex: 0x6B7280)
    static let brandBlue        = Color(hex: 0x3E53FF)
    static let gradientStart    = Color(hex: 0x4D60F8)
    static let gradientEnd      = Color(hex: 0x2C3DD8)

    private init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red:     Double((hex >> 16) & 0xFF) / 255,
            green:   Double((hex >> 8)  & 0xFF) / 255,
            blue:    Double(hex         & 0xFF) / 255,
            opacity: opacity
        )
    }
}
