//
//  ContentView.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI
import AVFoundation
import LocalAuthentication

struct ContentView: View {
    // ⚠️ 임시(테스트용): true면 권한/온보딩을 건너뛰고 도어락 목록부터 시작해
    // 목록 → 정보 수정 흐름을 시뮬레이터/실기기에서 바로 확인할 수 있다.
    // 테스트가 끝나면 false로 되돌릴 것.
    private let showDoorLockListForTesting = true

    @State private var hasGrantedPermissions = false
    @State private var onboardingStep = 0

    var body: some View {
        if showDoorLockListForTesting {
            NavigationStack {
                DoorLockListView()
            }
        } else {
            mainFlow
        }
    }

    @ViewBuilder
    private var mainFlow: some View {
        if !hasGrantedPermissions {
            PermissionSetupView {
                requestPermissions()
            }
        } else if onboardingStep < OnboardingPage.all.count {
            OnboardingPageView(
                page: OnboardingPage.all[onboardingStep],
                currentStep: onboardingStep,
                totalSteps: OnboardingPage.all.count
            ) {
                onboardingStep += 1
            }
        } else {
            // 온보딩 완료 → 인식 화면. 가이드 박스·인식 로직은 ObjectRecongnitionView에서 구현 예정
            ObjectRecongnitionView()
        }
    }

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
            guard cameraGranted else { return }

            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "비밀번호를 본인에게만 보여주기 위해 필요해요"
                ) { success, _ in
                    if success {
                        Task { @MainActor in hasGrantedPermissions = true }
                    }
                }
            } else {
                // Face ID를 사용할 수 없는 기기 (Touch ID, 패스코드 등)
                Task { @MainActor in hasGrantedPermissions = true }
            }
        }
    }
}

#Preview {
    ContentView()
}
