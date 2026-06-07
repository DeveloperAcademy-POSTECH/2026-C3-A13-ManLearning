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
}
