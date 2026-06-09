//
//  ContentView.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    // 첫 실행 여부 영속. true면 권한/온보딩을 건너뛰고 곧장 메인 탭바(카메라)로 진입.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var hasGrantedPermissions = false
    @State private var onboardingStep = 0
    
    var body: some View {
        if hasCompletedOnboarding {
            // 온보딩 완료 후(또는 재실행): 메인 탭바 — 기본 scan(카메라) 탭
            MainTabView()
        } else if !hasGrantedPermissions {
            PermissionSetupView {
                requestPermissions()
            }
        } else if onboardingStep < OnboardingPage.all.count {
            OnboardingPageView(
                page: OnboardingPage.all[onboardingStep],
                currentStep: onboardingStep,
                totalSteps: OnboardingPage.all.count
            ) {
                // 마지막 페이지 "등록하러 가기" → 온보딩 완료 처리 → MainTabView(카메라)
                if onboardingStep == OnboardingPage.all.count - 1 {
                    hasCompletedOnboarding = true
                } else {
                    onboardingStep += 1
                }
            }
        }
    }
    
    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
            guard cameraGranted else { return }
            Task { @MainActor in hasGrantedPermissions = true }
        }
    }
}

#Preview {
    ContentView()
}
