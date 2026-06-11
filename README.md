# DoUnlock

DoUnlock은 팀 ManLearning의 iOS 앱 프로젝트입니다.

## 프로젝트 구조

기능(화면) 단위로 폴더를 나누는 **feature-first** 구조입니다.

```text
DoUnlock/DoUnlock/
├── App/             # 앱 진입점·라우팅 (DoUnlockApp, ContentView, AppRouter, MainTabView)
├── Models/          # SwiftData 모델 (DoorLockModel, DoorLock+Display)
├── DesignTokens/    # 디자인 시스템 (색·폰트·텍스트 스타일 — 규칙은 내부 README 참고)
├── Camera/          # 등록·인식 화면이 공유하는 카메라/가이드박스
├── Onboarding/      # 권한 요청 + 온보딩 3페이지
├── Registration/    # 잠금장치 등록 플로우 (촬영 → 리뷰 → 폼 → 완료) + 등록 전용 YOLO 탐지
├── Recognition/     # 잠금장치 인식 플로우 (유사도 비교 → Face ID → 비밀번호 표시)
├── LockList/        # 등록된 잠금장치 목록
├── Share/           # 근거리 공유 (MultipeerConnectivity + 보내기/받기 시트)
├── Fonts/           # Pretendard .otf
├── model/           # Git 제외: 팀에서 별도 공유받은 Core ML 모델 파일을 로컬에 배치
├── Assets.xcassets
└── Info.plist       # 위치 고정 (pbxproj가 이 경로를 참조)
```

### 폴더 구조 규칙

1. **새 파일은 해당 기능 폴더에 둡니다.** "이 화면을 고치려면 이 폴더만 보면 된다"가 성립해야 합니다. 역할별 폴더(Views/, ViewModels/ 등)로 나누면 한 화면 작업에 폴더 3~4개를 오가게 되어 채택하지 않았습니다.
2. **공유 폴더 승격은 두 번째 사용처가 생긴 뒤에.** 예: YOLO 탐지는 등록에서만 쓰여 `Registration/`에, 유사도 비교는 인식에서만 쓰여 `Recognition/`에 있습니다. 카메라 프리뷰·가이드박스는 두 화면이 실제로 공유해서 `Camera/`로 올렸습니다. 미리 "공용일 것 같아서" 옮기지 않습니다.
3. **파일 이동은 안전합니다.** Swift는 경로 기반 import가 없어 파일을 옮겨도 코드 수정이 필요 없고, Xcode 26의 폴더 동기화(PBXFileSystemSynchronizedRootGroup) 덕분에 Finder/`git mv`로 옮기면 프로젝트에 그대로 반영됩니다. 단 `Info.plist`는 pbxproj가 경로를 직접 참조하므로 이동 금지.

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
6. 팀에서 공유받은 `model/` 폴더를 `DoUnlock/DoUnlock/model/` 경로에 배치합니다.
7. 빌드할 기기를 선택한 뒤 실행합니다.

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