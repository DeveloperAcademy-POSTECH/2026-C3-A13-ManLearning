//
//  Font+Tokens.swift
//  DoUnlock
//
//  Figma의 폰트 원시 값(font-family, size)을 정의합니다.
//  tracking / lineSpacing 등 조합이 필요한 경우 TextStyle.swift를 사용하세요.
//
//  주의: SwiftUI 내장 Font 멤버(.body, .caption, .title 등)와 이름이 겹치면
//  재선언 에러가 납니다. (그래서 body→bodyText, caption→captionText 로 명명)
//

import SwiftUI

extension Font {
    static let heading        = Font.custom("Pretendard-Black",     size: 30)
    static let completionTitle = Font.custom("Pretendard-Bold",      size: 30)  // 완료 화면 대제목
    static let displayTitle = Font.custom("Pretendard-ExtraBold", size: 30)  // 온보딩 대형 타이틀
    static let navTitle     = Font.custom("Pretendard-Bold",      size: 20)  // 화면 상단 타이틀
    static let brandName    = Font.custom("Pretendard-Bold",      size: 22)
    static let subHeading   = Font.custom("Pretendard-Regular",   size: 17)
    static let leadBody     = Font.custom("Pretendard-Medium",    size: 20)  // 리드 본문
    static let bodyText     = Font.custom("Pretendard-Regular",   size: 18)
    static let cardTitle    = Font.custom("Pretendard-Bold",      size: 15)
    static let cardSubtitle = Font.custom("Pretendard-SemiBold",  size: 13)
    static let fieldLabel   = Font.custom("Pretendard-SemiBold",  size: 13)
    static let fieldValue   = Font.custom("Pretendard-SemiBold",  size: 14)
    static let button       = Font.custom("Pretendard-Black",     size: 15)
    static let buttonLarge  = Font.custom("Pretendard-SemiBold",  size: 18)
    static let captionText  = Font.custom("Pretendard-Regular",   size: 12)
    static let badge        = Font.custom("Pretendard-Medium",    size: 11)
}
