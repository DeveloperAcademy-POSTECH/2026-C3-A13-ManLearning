//
//  ContentView.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        // FaceIDView 테스트를 위한 NavigationStack입니다.
        // Face ID 구현이 완료된 후에는 인증 결과에 따라 카메라 뷰로 전환하는 분기를 추가할 예정입니다.
        NavigationStack {
            ZStack {
                CameraPreviewView(
                    isActive: true, frameHandler: { _ in }
                ).ignoresSafeArea()

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
        
    


#Preview {
    ContentView()
}
