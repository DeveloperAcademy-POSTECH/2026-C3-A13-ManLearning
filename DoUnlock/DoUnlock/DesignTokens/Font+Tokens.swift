//
//  Font+Tokens.swift
//  DoUnlock
//
//  Figma의 폰트 원시 값(font-family, size)을 정의합니다.
//  tracking / lineSpacing 등 조합이 필요한 경우 TextStyle.swift를 사용하세요.
//

import SwiftUI

extension Font {
    static let brandName    = Font.custom("Pretendard-Bold",     size: 22)
    static let heading      = Font.custom("Pretendard-Bold",     size: 30)
    static let button1      = Font.custom("Pretendard-SemiBold", size: 18)
    static let bodyText     = Font.custom("Pretendard-Regular",  size: 18)
    static let cardTitle    = Font.custom("Pretendard-Bold",     size: 15)
    static let cardSubtitle = Font.custom("Pretendard-SemiBold", size: 13)
}
