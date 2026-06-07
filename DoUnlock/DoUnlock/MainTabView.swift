//
//  MainTabView.swift
//  DoUnlock
//
//  앱 메인 탭바: scan(카메라) / password(도어락 목록).
//  권한·온보딩 완료 후 진입하는 루트 화면.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            // 촬영/등록 — ObjectDetectView (내부에 촬영→리뷰→등록→완료 cover 보유)
            NavigationStack {
                ObjectDetectView()
            }
            .tabItem { Label("scan", systemImage: "viewfinder") }
            .tag(AppRouter.Tab.scan)

            // 도어락 목록 (Figma: 자물쇠 + password)
            NavigationStack {
                DoorLockListView()
            }
            .tabItem { Label("password", systemImage: "lock.fill") }
            .tag(AppRouter.Tab.password)
        }
        .environment(router)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: DoorLock.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return MainTabView()
        .modelContainer(container)
}
