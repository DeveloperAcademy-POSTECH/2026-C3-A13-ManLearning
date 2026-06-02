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
    @State private var hasGrantedPermissions = false

    var body: some View {
        if !hasGrantedPermissions {
            PermissionSetupView {
                requestPermissions()
            }
        } else {
            // FaceIDView 테스트를 위한 NavigationStack입니다.
            // Face ID 구현이 완료된 후에는 인증 결과에 따라 카메라 뷰로 전환하는 분기를 추가할 예정입니다.
            NavigationStack {
                ZStack {
                    CameraPreviewView(isActive: true, frameHandler: { _ in })
                        .ignoresSafeArea()

                    // 테스트용 진입 버튼 — 추후 조건 로직으로 교체 예정
                    VStack {
                        Spacer()
                        NavigationLink("Face ID 테스트") {
                            FaceIDView()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 48)
                    }
                }
                .navigationTitle("DoUnlock")
                .navigationBarTitleDisplayMode(.inline)
            }
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
