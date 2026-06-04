//
//  TextStyle.swift
//  DoUnlock
//
//  디자인 토큰 → 텍스트 스타일 조합 레이어.
//  Font+Tokens.swift의 원시 폰트 값과 tracking/lineSpacing을 하나의 스타일로 묶습니다.
//  색상(foregroundStyle)은 배경에 따라 달라질 수 있으므로 호출부에서 별도로 지정합니다.
//
//  새 스타일 추가 방법:
//    1. TextStyle enum에 케이스 추가
//    2. AppTextModifier의 switch에 해당 케이스 구현
//    3. 필요하면 Font+Tokens.swift에 원시 폰트 값도 추가
//

import SwiftUI

// MARK: - TextStyle

enum TextStyle {
    case heading        // 페이지 대제목
    case brandName      // 앱 로고 옆 이름
    case subHeading     // 부제목 / 안내 본문 (lineSpacing 포함)
    case bodyText       // 본문 설명 (lineSpacing 포함)
    case cardTitle      // 카드 주 제목
    case cardSubtitle   // 카드 부제목
    case fieldLabel     // 입력 필드 레이블
    case fieldValue     // 입력 필드 값
    case button         // CTA 버튼 (강조, Black)
    case buttonLarge    // CTA 버튼 (보조, SemiBold)
    case caption        // 안내 / 보조 설명
    case badge          // 상태 뱃지
}

// MARK: - ViewModifier

struct AppTextModifier: ViewModifier {
    let style: TextStyle

    func body(content: Content) -> some View {
        switch style {
        case .heading:
            content.font(.heading).tracking(-0.5)
        case .brandName:
            content.font(.brandName).tracking(-0.5)
        case .subHeading:
            content.font(.subHeading).lineSpacing(8)
        case .bodyText:
            // lineHeight 25 - fontSize 18 = lineSpacing 7
            content.font(.bodyText).lineSpacing(7)
        case .cardTitle:
            content.font(.cardTitle).tracking(-0.375)
        case .cardSubtitle:
            content.font(.cardSubtitle).tracking(-0.375)
        case .fieldLabel:
            content.font(.fieldLabel)
        case .fieldValue:
            content.font(.fieldValue)
        case .button:
            content.font(.button).tracking(-0.375)
        case .buttonLarge:
            content.font(.buttonLarge).tracking(-0.375)
        case .caption:
            content.font(.captionText)
        case .badge:
            content.font(.badge)
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
