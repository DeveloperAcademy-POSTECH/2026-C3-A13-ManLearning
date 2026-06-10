## 작업 내용
<!-- 무엇을, 왜 -->
- 온보딩 화면에 페이지 스와이프 애니메이션 적용
  - `OnboardingPageView`가 자체적으로 `currentStep`, `dragOffset` 상태를 관리하도록 변경
  - 좌우 드래그로 페이지 전환 가능하도록 스와이프 제스처 추가 (첫/마지막 페이지에서는 고무줄 저항감 적용)
  - 드래그 가능 영역을 콘텐츠뿐 아니라 그 아래 빈 여백까지 포함 (프로그레스 바 ~ 다음 버튼 사이 전체)
  - 진행 상태 바 및 페이지 전환에 `easeInOut` 애니메이션 추가
  - `ContentView`는 `onboardingStep` 상태를 들고 있지 않고, 온보딩 완료 콜백만 전달하도록 단순화
- 사용하지 않는 boundingBox 관련 코드 정리
  - `CapturedImageReviewView`, `ObjectDetectView`, `DetectionViewModel`에서 더 이상 쓰이지 않는 `boundingBox` / `latestDetection` 관련 로직 제거
  - 캡처 리뷰 화면은 항상 가이드 영역(`guideRect`) 기준으로 표시

## 변경 파일
- `DoUnlock/DoUnlock/Onboarding/OnboardingPageView.swift`
- `DoUnlock/DoUnlock/ContentView.swift`
- `DoUnlock/DoUnlock/CapturedImageReviewView.swift`
- `DoUnlock/DoUnlock/ObjectDetectView.swift`

## 테스트 방법
<!-- 시뮬레이터/실기기 어디서 어떻게 확인 -->
- 시뮬레이터에서 앱 최초 실행 후 온보딩 진행
  - 다음 버튼으로 페이지 이동 시 애니메이션 확인
  - 좌우 스와이프로 페이지 전환 확인 (첫/마지막 페이지에서 저항감 확인)
  - 콘텐츠 영역뿐 아니라 그 아래 빈 공간을 드래그해도 동일하게 페이지가 따라 움직이는지 확인
  - 마지막 페이지에서 "등록하러 가기" 버튼으로 메인 탭바 진입 확인
- 카메라 촬영 → 캡처 리뷰 화면에서 가이드 박스 정상 표시 확인

## 참고 / 리뷰 포인트
<!-- 리뷰어가 특히 봐줬으면 하는 부분, 담당 경계 등 -->
- 스와이프 제스처의 임계값(`pageWidth / 3`)과 애니메이션 duration(0.32s)이 체감상 적절한지 확인 부탁
- boundingBox 제거로 인해 향후 객체 인식 박스 표시 기능이 필요해질 경우 별도 작업 필요
