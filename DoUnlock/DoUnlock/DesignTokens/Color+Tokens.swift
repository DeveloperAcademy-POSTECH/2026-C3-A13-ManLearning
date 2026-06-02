import SwiftUI

extension Color {
    // MARK: - Background
    static let screenBg = Color(red: 241/255, green: 239/255, blue: 239/255)
    static let surface = Color.white

    // MARK: - Brand
    static let brandPrimary = Color(red: 62/255, green: 83/255, blue: 255/255)
    static let brandPrimaryTint = Color(red: 62/255, green: 83/255, blue: 255/255).opacity(0.16)

    // MARK: - Text
    static let textPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let textSecondary = Color(red: 55/255, green: 65/255, blue: 81/255)
    static let textMuted = Color(red: 107/255, green: 114/255, blue: 128/255)
    static let textTertiary = Color(red: 156/255, green: 163/255, blue: 175/255)
    static let textPlaceholder = Color(red: 214/255, green: 214/255, blue: 214/255)

    // MARK: - Border / Divider
    static let borderDefault = Color(red: 229/255, green: 231/255, blue: 235/255)

    // MARK: - Info notice
    static let infoBg = Color(red: 238/255, green: 240/255, blue: 255/255)
    static let infoBorder = Color(red: 209/255, green: 217/255, blue: 250/255)
    static let infoFg = Color(red: 79/255, green: 91/255, blue: 153/255)

    // MARK: - Status
    static let successBg = Color(red: 220/255, green: 252/255, blue: 231/255)
    static let successFg = Color(red: 22/255, green: 163/255, blue: 74/255)

    // MARK: - Door lock icon gradient
    static let lockIconStart = Color(red: 18/255, green: 18/255, blue: 42/255)
    static let lockIconEnd = Color(red: 26/255, green: 24/255, blue: 56/255)
}
