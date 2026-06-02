import SwiftUI

enum TextStyle {
    case heading        // Pretendard-Black  30pt  tracking -0.5
    case subHeading     // Pretendard-Regular 17pt
    case cardTitle      // Pretendard-Bold    15pt
    case cardSubtitle   // Pretendard-SemiBold 13pt
    case fieldLabel     // Pretendard-SemiBold 13pt
    case fieldValue     // Pretendard-SemiBold 14pt
    case button         // Pretendard-Black   15pt  tracking -0.375
    case buttonLarge    // Pretendard-SemiBold 18pt  tracking -0.375
    case caption        // Pretendard-Regular  12pt
    case badge          // Pretendard-Medium   11pt
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TextStyle

    func body(content: Content) -> some View {
        styled(content)
    }

    @ViewBuilder
    private func styled(_ content: Content) -> some View {
        switch style {
        case .heading:
            content
                .font(.custom("Pretendard-Black", size: 30))
                .tracking(-0.5)
        case .subHeading:
            content
                .font(.custom("Pretendard-Regular", size: 17))
                .lineSpacing(8)
        case .cardTitle:
            content
                .font(.custom("Pretendard-Bold", size: 15))
        case .cardSubtitle:
            content
                .font(.custom("Pretendard-SemiBold", size: 13))
        case .fieldLabel:
            content
                .font(.custom("Pretendard-SemiBold", size: 13))
        case .fieldValue:
            content
                .font(.custom("Pretendard-SemiBold", size: 14))
        case .button:
            content
                .font(.custom("Pretendard-Black", size: 15))
                .tracking(-0.375)
        case .buttonLarge:
            content
                .font(.custom("Pretendard-SemiBold", size: 18))
                .tracking(-0.375)
        case .caption:
            content
                .font(.custom("Pretendard-Regular", size: 12))
        case .badge:
            content
                .font(.custom("Pretendard-Medium", size: 11))
        }
    }
}
