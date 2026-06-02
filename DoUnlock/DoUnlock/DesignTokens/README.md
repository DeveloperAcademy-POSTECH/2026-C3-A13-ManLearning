# DoUnlock 디자인 토큰 시스템

Figma 디자인 값을 코드로 가져오는 규칙을 정리합니다.
새 화면을 만들 때 이 규칙을 따르면 Figma와 코드의 불일치를 방지할 수 있습니다.

---

## 파일 구조

```
DesignTokens/
├── Color+Tokens.swift   — 색상 원시 값
├── Font+Tokens.swift    — 폰트 원시 값 (family, size)
└── TextStyle.swift      — 텍스트 스타일 조합 (font + tracking + lineSpacing)
```

두 레이어로 나뉩니다.

```
Figma → Color+Tokens / Font+Tokens (원시 값)
                ↓
           TextStyle (조합된 스타일)
                ↓
             Views (색상은 호출부에서)
```

---

## 색상 사용법

`Color+Tokens.swift`에 정의된 정적 프로퍼티를 사용합니다.

```swift
// 사용
.foregroundStyle(Color.headingText)
.background(Color.screenBackground)

// 절대 하드코딩 금지
.foregroundStyle(Color(hex: "#0F172A"))  // ❌
.foregroundStyle(.black)                 // ❌ (의미가 불분명)
```

| 토큰 | 용도 |
|------|------|
| `Color.screenBackground` | 화면 배경 `#F1EFEF` |
| `Color.headingText` | 제목 텍스트 `#0F172A` |
| `Color.secondaryText` | 설명 텍스트 `#6B7280` |
| `Color.brandBlue` | 버튼, 강조 `#3E53FF` |
| `Color.gradientStart` | 아이콘 그라데이언트 시작 `#4D60F8` |
| `Color.gradientEnd` | 아이콘 그라데이언트 끝 `#2C3DD8` |

---

## 텍스트 스타일 사용법

`.textStyle()` 하나로 font + tracking + lineSpacing을 한 번에 적용합니다.
색상(`foregroundStyle`)은 맥락에 따라 달라질 수 있으므로 호출부에서 별도로 지정합니다.

```swift
// 올바른 사용
Text("비밀번호를 확인")
    .textStyle(.heading)
    .foregroundStyle(Color.headingText)

// 하면 안 되는 것 — font와 tracking을 따로 쓰면 tracking을 빠뜨리기 쉬움
Text("비밀번호를 확인")
    .font(.heading)
    .tracking(-0.5)    // ❌ TextStyle.swift 바꿔도 여기는 안 바뀜
```

| 케이스 | Figma 토큰 | 용도 |
|--------|-----------|------|
| `.heading` | Heading | 페이지 대제목 |
| `.brandName` | Brand Name | 앱 로고 옆 이름 |
| `.button1` | button1 | CTA 버튼 레이블 |
| `.bodyText` | — | 본문 설명 (lineSpacing 포함) |
| `.cardTitle` | — | 카드 주 제목 |
| `.cardSubtitle` | — | 카드 부제목 |

---

## 새 텍스트 스타일 추가하는 법

Figma에 새 토큰이 생기면 `TextStyle.swift` 한 곳만 수정합니다.

```swift
// 1. enum에 케이스 추가
enum TextStyle {
    // ...기존 케이스들
    case caption   // ← 추가
}

// 2. switch에 구현 추가
case .caption:
    content
        .font(.custom("Pretendard-Regular", size: 12))
        .tracking(-0.2)
```

`Font+Tokens.swift`에도 추가가 필요하면 같이 추가합니다.

---

## 새 색상 추가하는 법

```swift
// Color+Tokens.swift에 추가
static let warningRed = Color(hex: 0xFF3B30)
```

---

## foregroundStyle을 토큰에 넣지 않는 이유

같은 텍스트 스타일(`.heading`)이라도 배경에 따라 색이 달라질 수 있습니다.
예를 들어 어두운 배경 위에서는 흰색 heading이 필요할 수 있습니다.
색을 스타일에 고정하면 재사용이 불가능해지므로 분리합니다.
