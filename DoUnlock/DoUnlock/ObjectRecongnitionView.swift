//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import SwiftUI

struct ObjectRecongnitionView: View {
    var body: some View {
        ZStack {
            CameraPreviewView(
                isActive: true,
                captureImageTrigger: false,
                pixelHandler: { pixelBuffer, cropRect in
                    // 이 cropRect가 화면 중앙 네모칸에 해당하는 픽셀 영역
                    // 실시간 코사인 유사도 비교는 여기서 cropRect 기준으로 처리
                },
                imageHandler: { image in
                    // 이 image는 화면 중앙 네모칸 영역만 crop된 이미지
                }
            )
            .ignoresSafeArea()


        }
    }
}


#Preview {
    ObjectRecongnitionView()
}
