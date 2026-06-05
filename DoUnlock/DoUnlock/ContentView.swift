//
//  ContentView.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI
import AVFoundation

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
                // 권한 통과 후에는 객체 인식/유사도 비교 화면을 진입점으로 사용합니다.
                // 카메라 조립과 DINO 비교 로직은 ObjectRecongnitionView 안에서 관리합니다.
                ObjectRecongnitionView()
                    .navigationTitle("DoUnlock")
                    .navigationBarTitleDisplayMode(.inline)
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
