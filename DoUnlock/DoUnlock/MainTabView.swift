//
//  MainTabView.swift
//  DoUnlock
//
//  앱 메인 탭바: scan(카메라) / password(도어락 목록).
//  권한·온보딩 완료 후 진입하는 루트 화면.
//

import SwiftUI
import SwiftData

/// scan 탭 루트: 등록 화면과 분리된 인식 전용 탭.
private struct ScanTabRootView: View {
    @Query private var doorLocks: [DoorLock]

    var body: some View {
        Group {
            if doorLocks.isEmpty {
                ScanEmptyStateView()
            } else {
                ObjectRecongnitionView()
            }
        }
    }
}

private struct ScanEmptyStateView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryTint)
                        .frame(width: 88, height: 88)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.brandPrimary)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .background(Color.screenBg, in: Circle())
                        .offset(x: 25, y: 24)
                }

                VStack(spacing: 8) {
                    Text("등록된 도어락이 없어요")
                        .textStyle(.heading)
                        .foregroundStyle(Color.textPrimary)

                    Text("카메라로 새 도어락을 먼저 등록해 주세요")
                        .textStyle(.subHeading)
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.center)
                }

                Button {
                    router.isDoorLockRegistrationPresented = true
                } label: {
                    Text("새 도어락 등록하기")
                        .textStyle(.buttonLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 53)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
        }
    }
}

struct MainTabView: View {
    @Query private var doorLocks: [DoorLock]
    @State private var router = AppRouter()
    @State private var didPresentInitialRegistration = false

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
        .fullScreenCover(
            isPresented: $router.isDoorLockRegistrationPresented,
            onDismiss: {
                moveToPendingTabAfterRegistrationDismiss()
            }
        ) {
            RegistrationFlowView()
                .environment(router)
        }
        .task {
            presentInitialRegistrationIfNeeded()
        }
    }

    private func presentInitialRegistrationIfNeeded() {
        guard !didPresentInitialRegistration, doorLocks.isEmpty else { return }
        didPresentInitialRegistration = true
        router.isDoorLockRegistrationPresented = true
    }

    private func moveToPendingTabAfterRegistrationDismiss() {
        guard let pendingTab = router.pendingTabAfterRegistrationDismiss else { return }
        router.pendingTabAfterRegistrationDismiss = nil
        router.selectedTab = pendingTab
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
