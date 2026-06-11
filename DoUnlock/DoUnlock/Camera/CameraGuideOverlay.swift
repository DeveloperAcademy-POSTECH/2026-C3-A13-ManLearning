//
//  CameraGuideOverlay.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import SwiftUI

enum StrokeColor {
    case idle
    case error
    case pass

    var color: Color {
        switch self {
        case .idle:  return .white
        case .error: return .red
        case .pass:  return .green
        }
    }

    var notificationTitle: String {
        switch self {
        case .idle:  return "인식 가이드"
        case .error: return "인식 오류"
        case .pass:  return "인식 완료"
        }
    }

    var notificationSubtitle: String {
        switch self {
        case .idle:  return "가이드 박스 안에 잠금장치가\n들어가게 해주세요."
        case .error: return "가이드 화면 안에 들어오도록\n카메라를 비춰주세요"
        case .pass:  return "촬영 버튼을 눌러주세요"
        }
    }
}

struct CameraGuideOverlay: View {
    let widthRatio: CGFloat = 0.63
    let heightRatio: CGFloat = 0.45
    @Binding var status: StrokeColor

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 가이드 박스
                Rectangle()
                    .stroke(status.color, lineWidth: 3)
                    .frame(
                        width: geometry.size.width * widthRatio,
                        height: geometry.size.height * heightRatio
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    .animation(.easeInOut(duration: 0.3), value: status.color)

                // 알림 카드
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.notificationTitle)
                        .font(.custom("Pretendard-Medium", size: 18))
                        .foregroundColor(.white)
                    Text(status.notificationSubtitle)
                        .font(.custom("Pretendard-Regular", size: 13))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(width: geometry.size.width * widthRatio, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 - geometry.size.height * heightRatio / 2 - 56
                )
                .animation(.easeInOut(duration: 0.3), value: status.notificationTitle)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CameraGuideOverlay(status: .constant(.idle))
    }
}
