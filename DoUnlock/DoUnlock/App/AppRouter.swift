//
//  AppRouter.swift
//  DoUnlock
//
//  탭바 선택 상태. environment로 주입해 목록 등 하위 화면이 탭을 전환할 수 있게 한다.
//

import SwiftUI

@Observable
final class AppRouter {
    enum Tab {
        case scan      // 카메라(ObjectRecognitionView) — 인식
        case password  // 잠금장치 목록(DoorLockListView)
    }

    var selectedTab: Tab = .scan

    /// 등록 완료 화면("목록 확인하기")에서 등록 플로우를 끝내고 목록으로 보내야 함을 알리는 신호.
    /// RegistrationFlowView가 이 값을 관찰해 등록 cover를 닫고 false로 리셋한다.
    var finishCaptureFlowRequested = false

    /// 목록 화면의 "새 잠금장치 등록하기"에서 등록 촬영 플로우를 전체 화면으로 띄울 때 사용한다.
    var isDoorLockRegistrationPresented = false

    /// 등록 완료 화면 "바로 인식해보기"에서 등록 플로우를 끝내고 scan 탭 인식 화면으로 보내야 함을 알리는 신호.
    /// RegistrationFlowView가 이 값을 관찰해 등록 cover를 닫고 false로 리셋한다.
    var finishCaptureAndScanRequested = false

    /// 등록 cover가 완전히 닫힌 뒤 MainTabView가 이동해야 할 탭.
    /// cover dismiss 애니메이션과 탭 전환이 동시에 일어나 화면이 겹쳐 보이는 현상을 막기 위해 사용한다.
    var pendingTabAfterRegistrationDismiss: Tab?
}
