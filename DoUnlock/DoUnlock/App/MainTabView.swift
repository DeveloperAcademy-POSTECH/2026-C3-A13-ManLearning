//
//  MainTabView.swift
//  DoUnlock
//
//  앱 메인 탭바: scan(카메라) / password(잠금장치 목록).
//  권한·온보딩 완료 후 진입하는 루트 화면.
//

import SwiftUI
import SwiftData

/// scan 탭 루트: 등록 화면과 분리된 인식 전용 탭.
private struct ScanTabRootView: View {
    var body: some View {
        ObjectRecognitionView()
    }
}

struct MainTabView: View {
    @Query private var doorLocks: [DoorLock]
    @State private var router = AppRouter()

    private var hasRegisteredDoorLocks: Bool {
        doorLocks.isEmpty == false
    }

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            if hasRegisteredDoorLocks {
                NavigationStack {
                    ScanTabRootView()
                }
                .tabItem { Label("scan", systemImage: "camera.fill") }
                .tag(AppRouter.Tab.scan)
            }

            // 잠금장치 목록 (Figma: 자물쇠 + password)
            NavigationStack {
                DoorLockListView()
            }
            .tabItem { Label("password", systemImage: "lock.fill") }
            .tag(AppRouter.Tab.password)
        }
        .environment(router)
        .fullScreenCover(
            isPresented: $router.isDoorLockRegistrationPresented,
            onDismiss: {
                moveToPendingTabAfterRegistrationDismiss()
            }
        ) {
            RegistrationFlowView()
                .environment(router)
        }
        .onChange(of: hasRegisteredDoorLocks) { _, hasLocks in
            if hasLocks == false {
                router.selectedTab = .password
            }
        }
    }

    private func moveToPendingTabAfterRegistrationDismiss() {
        guard let pendingTab = router.pendingTabAfterRegistrationDismiss else { return }
        router.pendingTabAfterRegistrationDismiss = nil
        router.selectedTab = pendingTab == .scan && doorLocks.isEmpty ? .password : pendingTab
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
