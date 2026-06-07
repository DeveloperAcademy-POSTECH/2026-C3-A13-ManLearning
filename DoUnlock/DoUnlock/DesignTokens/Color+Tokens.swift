//
//  Color+Tokens.swift
//  DoUnlock
//
//  Figma 색상 원시 값을 시맨틱 이름으로 정의합니다.
//  값은 hex 리터럴로, 이름은 "역할" 기준으로 짓습니다. (색조를 이름에 박지 않음 — brandBlue ❌ / brandPrimary ✅)
//

import SwiftUI

extension Color {
    // MARK: - Background
    static let screenBg          = Color(hex: 0xF1EFEF)   // 화면 배경
    static let surface           = Color.white            // 카드 / 입력 필드 표면

    // MARK: - Brand
    static let brandPrimary      = Color(hex: 0x3E53FF)   // 버튼, 강조
    static let brandPrimaryTint  = Color(hex: 0x3E53FF, opacity: 0.16)
    static let brandGradientStart = Color(hex: 0x4D60F8)  // 앱 아이콘 그라데이션 시작
    static let brandGradientEnd   = Color(hex: 0x2C3DD8)  // 앱 아이콘 그라데이션 끝

    // MARK: - Text
    static let textPrimary       = Color(hex: 0x0F172A)   // 제목 / 본문 강조
    static let textSecondary     = Color(hex: 0x374151)   // 레이블
    static let textMuted         = Color(hex: 0x6B7280)   // 설명 텍스트
    static let textTertiary      = Color(hex: 0x9CA3AF)
    static let textPlaceholder   = Color(hex: 0xD6D6D6)

    // MARK: - Border / Divider
    static let borderDefault     = Color(hex: 0xE5E7EB)

    // MARK: - Progress
    static let progressTrack     = Color(hex: 0xD9D9D9)   // 진행바 비활성 트랙

    // MARK: - Info notice
    static let infoBg            = Color(hex: 0xEEF0FF)
    static let infoBorder        = Color(hex: 0xD1D9FA)
    static let infoFg            = Color(hex: 0x4F5B99)

    // MARK: - Status
    static let successBg         = Color(hex: 0xDCFCE7)
    static let successFg         = Color(hex: 0x16A34A)
    static let destructiveBg     = Color(hex: 0xFF383C, opacity: 0.14)  // "나중에" 등 거절 버튼 배경
    static let destructiveFg     = Color(hex: 0xFF383C)                 // 거절 버튼 텍스트

    // MARK: - Door lock icon gradient
    static let lockIconStart     = Color(hex: 0x12122A)
    static let lockIconEnd       = Color(hex: 0x1A1838)

    // MARK: - Door lock card thumbnail (사진 없을 때 placeholder)
    static let lockBadgeBg       = Color(hex: 0x161530)   // 배경
    static let lockBadgeIcon     = Color(hex: 0x6B7BF7)   // 자물쇠 글리프

    // MARK: - hex initializer
    private init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red:     Double((hex >> 16) & 0xFF) / 255,
            green:   Double((hex >> 8)  & 0xFF) / 255,
            blue:    Double(hex         & 0xFF) / 255,
            opacity: opacity
        )
    }
}
