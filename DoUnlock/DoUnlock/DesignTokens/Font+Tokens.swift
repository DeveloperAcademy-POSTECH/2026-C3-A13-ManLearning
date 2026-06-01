//
//  Font+Tokens.swift
//  DoUnlock
//

import SwiftUI

extension Font {
    // Figma 토큰: "Brand Name" — Pretendard Bold 22px, tracking -0.5
    static let brandName = Font.custom("Pretendard-Bold", size: 22)

    // Figma 토큰: "Heading" — Pretendard Bold 30px, tracking -0.5
    static let heading = Font.custom("Pretendard-Bold", size: 30)

    // Figma 토큰: "button1" — Pretendard SemiBold 18px, tracking -0.375
    static let button1 = Font.custom("Pretendard-SemiBold", size: 18)

    // 본문 — Pretendard Regular 18px, lineHeight 25
    static let bodyText = Font.custom("Pretendard-Regular", size: 18)

    // 카드 제목 — Pretendard Bold 15px
    static let cardTitle = Font.custom("Pretendard-Bold", size: 15)

    // 카드 부제목 — Pretendard SemiBold 13px
    static let cardSubtitle = Font.custom("Pretendard-SemiBold", size: 13)
}
