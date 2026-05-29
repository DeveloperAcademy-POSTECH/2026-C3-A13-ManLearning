# DoUnlock

DoUnlock은 팀 ManLearning의 iOS 앱 프로젝트입니다.

## 프로젝트 구조
테스트 수정

```text
DoUnlock/
├── DoUnlock/
│   ├── Assets.xcassets
│   ├── ContentView.swift
│   └── DoUnlockApp.swift
└── DoUnlock.xcodeproj
```

## 개발 환경

- iOS
- Swift
- SwiftUI
- Xcode

## 실행 방법

1. 저장소를 클론합니다.
2. `DoUnlock/DoUnlock.xcodeproj` 파일을 Xcode로 엽니다.
3. 팀에서 공유받은 개발용 인증서 `.p12`를 설치합니다.
4. 팀에서 공유받은 provisioning profile을 설치합니다.
5. Xcode의 `Signing & Capabilities`에서 수동 서명 설정을 확인합니다.
6. 빌드할 기기를 선택한 뒤 실행합니다.

## Signing

이 프로젝트는 팀 개발을 위해 Manual Signing을 사용합니다.

인증서와 provisioning profile은 GitHub에 커밋하지 않고 팀 내부에서 별도로 공유합니다.

## Git 관리 제외 파일

이 저장소는 `.gitignore`를 통해 아래와 같은 로컬/보안 파일을 Git 관리에서 제외합니다.

```text
.DS_Store
DerivedData/
build/
xcuserdata/
*.xcuserstate
*.p12
*.cer
*.mobileprovision
*.provisionprofile
```

## Git 규칙

- `main` 브랜치는 안정적인 상태를 유지합니다.
- 기능 개발은 별도 브랜치에서 진행합니다.
- Pull Request를 통해 코드 리뷰 후 병합합니다.
