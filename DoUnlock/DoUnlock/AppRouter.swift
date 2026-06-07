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
        case scan      // 카메라(ObjectDetectView) — 촬영/등록
        case password  // 도어락 목록(DoorLockListView)
    }

    var selectedTab: Tab = .scan

    /// 등록 완료 화면("목록 확인하기")에서 촬영 플로우를 끝내고 목록으로 보내야 함을 알리는 신호.
    /// 촬영 cover(reviewData)는 ObjectDetectView가 소유하므로, 외부(완료 화면)에선 직접 닫지 못한다.
    /// ObjectDetectView가 이 값을 관찰해 cover를 닫고 selectedTab=.password로 전환한 뒤 false로 리셋한다.
    var finishCaptureFlowRequested = false
}
