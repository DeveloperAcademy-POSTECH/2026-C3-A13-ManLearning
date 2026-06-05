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
    @State private var cameraStatus: StrokeColor = .idle
    var body: some View {
        if !hasGrantedPermissions {
            PermissionSetupView {
                requestPermissions()
            }
        } else {
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
