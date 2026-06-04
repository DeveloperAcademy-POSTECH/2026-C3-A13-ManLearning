# DoUnlock 디자인 토큰 시스템

Figma 디자인 값을 코드로 가져오는 규칙을 정리합니다.
새 화면을 만들 때 이 규칙을 따르면 Figma와 코드의 불일치를 방지할 수 있습니다.

---

## 파일 구조

```
DesignTokens/
├── Color+Tokens.swift   — 색상 원시 값 (시맨틱 이름 + hex)
├── Font+Tokens.swift    — 폰트 원시 값 (family, size)
└── TextStyle.swift      — 텍스트 스타일 조합 (font + tracking + lineSpacing)
```

두 레이어로 나뉩니다.

```
Figma → Color+Tokens / Font+Tokens (원시 값)
                ↓
           TextStyle (조합된 스타일)
                ↓
             Views (색상은 호출부에서 foregroundStyle로)
```

---

## 색상 사용법

`Color+Tokens.swift`에 정의된 시맨틱 토큰을 사용합니다.
이름은 **역할 기준**으로 짓습니다 — 색조를 이름에 박지 않습니다 (`brandBlue` ❌ / `brandPrimary` ✅).

```swift
// 사용
.foregroundStyle(Color.textPrimary)
.background(Color.screenBg)

// 절대 하드코딩 금지
.foregroundStyle(Color(red: 15/255, ...))  // ❌
.foregroundStyle(.black)                    // ❌ (의미 불분명)
```

| 그룹 | 토큰 | 값 |
|------|------|------|
| Background | `screenBg` | `#F1EFEF` |
| | `surface` | white (카드/입력 표면) |
| Brand | `brandPrimary` | `#3E53FF` |
| | `brandPrimaryTint` | brandPrimary 16% |
| | `brandGradientStart` / `brandGradientEnd` | `#4D60F8` → `#2C3DD8` (앱 아이콘) |
| Text | `textPrimary` | `#0F172A` |
| | `textSecondary` | `#374151` |
| | `textMuted` | `#6B7280` |
| | `textTertiary` | `#9CA3AF` |
| | `textPlaceholder` | `#D6D6D6` |
| Border | `borderDefault` | `#E5E7EB` |
| Info | `infoBg` / `infoBorder` / `infoFg` | `#EEF0FF` / `#D1D9FA` / `#4F5B99` |
| Status | `successBg` / `successFg` | `#DCFCE7` / `#16A34A` |
| Icon | `lockIconStart` / `lockIconEnd` | `#12122A` → `#1A1838` |

---

## 텍스트 스타일 사용법

`.textStyle()` 하나로 font + tracking + lineSpacing을 한 번에 적용합니다.
색상(`foregroundStyle`)은 맥락에 따라 달라질 수 있으므로 호출부에서 별도로 지정합니다.

```swift
// 올바른 사용
Text("비밀번호를 확인")
    .textStyle(.heading)
    .foregroundStyle(Color.textPrimary)

// 하면 안 되는 것 — font와 tracking을 따로 쓰면 tracking을 빠뜨리기 쉬움
Text("비밀번호를 확인")
    .font(.heading)
    .tracking(-0.5)    // ❌ TextStyle.swift 바꿔도 여기는 안 바뀜
```

| 케이스 | 폰트 | 용도 |
|--------|------|------|
| `.heading` | Black 30 | 페이지 대제목 |
| `.brandName` | Bold 22 | 앱 로고 옆 이름 |
| `.subHeading` | Regular 17 | 부제목 / 안내 본문 |
| `.bodyText` | Regular 18 | 본문 설명 (lineSpacing 포함) |
| `.cardTitle` | Bold 15 | 카드 주 제목 |
| `.cardSubtitle` | SemiBold 13 | 카드 부제목 |
| `.fieldLabel` | SemiBold 13 | 입력 필드 레이블 |
| `.fieldValue` | SemiBold 14 | 입력 필드 값 |
| `.button` | Black 15 | CTA 버튼 (강조) |
| `.buttonLarge` | SemiBold 18 | CTA 버튼 (보조) |
| `.caption` | Regular 12 | 안내 / 보조 설명 |
| `.badge` | Medium 11 | 상태 뱃지 |

폰트는 Pretendard 전 weight가 번들되어 있습니다 (`Info.plist` UIAppFonts 등록 필요).

---

## 새 텍스트 스타일 추가하는 법

```swift
// 1. TextStyle.swift enum에 케이스 추가
enum TextStyle {
    // ...기존 케이스들
    case footnote   // ← 추가
}

// 2. AppTextModifier switch에 구현 추가
case .footnote:
    content.font(.footnoteText).tracking(-0.2)

// 3. Font+Tokens.swift에 원시 값 추가
//    ⚠️ SwiftUI 내장 Font 멤버(.body, .caption, .title 등)와 이름이 겹치면
//       재선언 에러가 납니다 → bodyText / captionText 처럼 접미사를 붙이세요.
static let footnoteText = Font.custom("Pretendard-Regular", size: 11)
```

---

## 새 색상 추가하는 법

```swift
// Color+Tokens.swift 에 시맨틱 이름으로 추가
static let warningFg = Color(hex: 0xFF3B30)
```

---

## foregroundStyle을 토큰에 넣지 않는 이유

같은 텍스트 스타일(`.heading`)이라도 배경에 따라 색이 달라질 수 있습니다.
예를 들어 어두운 배경 위에서는 흰색 heading이 필요할 수 있습니다.
색을 스타일에 고정하면 재사용이 불가능해지므로 분리합니다.
