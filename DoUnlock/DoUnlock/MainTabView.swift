//
//  MainTabView.swift
//  DoUnlock
//
//  앱 메인 탭바: scan(카메라) / password(도어락 목록).
//  권한·온보딩 완료 후 진입하는 루트 화면.
//

import SwiftUI
import SwiftData

/// scan 탭 루트: 등록된 DoorLock이 없으면 등록 화면, 있으면 인식 화면을 표시한다.
private struct ScanTabRootView: View {
    @Query private var doorLocks: [DoorLock]
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if doorLocks.isEmpty {
                ObjectDetectView()
            } else {
                ObjectRecongnitionView()
            }
        }
        .onChange(of: router.finishCaptureFlowRequested) { _, requested in
            guard requested else { return }
            router.selectedTab = .password
            router.finishCaptureFlowRequested = false
        }
    }
}

struct MainTabView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack {
                ScanTabRootView()
            }
            .tabItem { Label("scan", systemImage: "camera.fill") }
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
