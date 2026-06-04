//
//  TextStyle.swift
//  DoUnlock
//
//  디자인 토큰 → 텍스트 스타일 조합 레이어.
//  Font+Tokens.swift의 원시 폰트 값과 tracking/lineSpacing을 하나의 스타일로 묶습니다.
//
//  새 스타일 추가 방법:
//    1. TextStyle enum에 케이스 추가
//    2. AppTextModifier의 switch에 해당 케이스 구현
//    3. Figma 토큰 이름과 케이스 이름을 맞춰 유지
//

import SwiftUI

// MARK: - TextStyle

enum TextStyle {
    case heading        // Figma: "Heading"       — 페이지 제목
    case brandName      // Figma: "Brand Name"    — 앱 로고 옆 이름
    case button1        // Figma: "button1"       — CTA 버튼
    case bodyText       //                        — 본문 설명 (lineSpacing 포함)
    case cardTitle      //                        — 카드 주 제목
    case cardSubtitle   //                        — 카드 부제목
}

// MARK: - ViewModifier

struct AppTextModifier: ViewModifier {
    let style: TextStyle

    func body(content: Content) -> some View {
        switch style {
        case .heading:
            content
                .font(.heading)
                .tracking(-0.5)
        case .brandName:
            content
                .font(.brandName)
                .tracking(-0.5)
        case .button1:
            content
                .font(.button1)
                .tracking(-0.375)
        case .bodyText:
            // lineHeight 25 - fontSize 18 = lineSpacing 7
            content
                .font(.bodyText)
                .lineSpacing(7)
        case .cardTitle:
            content
                .font(.cardTitle)
                .tracking(-0.375)
        case .cardSubtitle:
            content
                .font(.cardSubtitle)
                .tracking(-0.375)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Figma 텍스트 토큰을 적용합니다. foregroundStyle은 호출부에서 별도 지정하세요.
    func textStyle(_ style: TextStyle) -> some View {
        modifier(AppTextModifier(style: style))
    }
}
