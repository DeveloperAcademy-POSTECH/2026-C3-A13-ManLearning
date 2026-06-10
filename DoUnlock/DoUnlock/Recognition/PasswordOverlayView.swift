//
//  PasswordOverlayView.swift
//  DoUnlock
//
//  Face ID 인증 후 카메라 화면 위에 띄우는 비밀번호 오버레이.
//  Figma: 비밀번호 보기(1개만 있을때) / 비밀번호 보기(2개 이상일 때) node-id 24:953, 64:1744

import Combine
import SwiftUI

struct PasswordOverlayView: View {
    let lock: DoorLock
    let isSingleMatch: Bool
    let onDismiss: () -> Void

    @State private var isPasswordVisible = false
    @State private var timeRemaining = 10

    private let countdown = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // CameraGuideOverlay 와 동일한 비율
    private let boxWidthRatio: CGFloat  = 0.63
    private let boxHeightRatio: CGFloat = 0.45

    // Figma 비율 상수 (402×872 프레임 기준)
    private let passwordYRatio: CGFloat = 194.0 / 872.0   // 22.25%
    private let buttonCenterYRatio: CGFloat = 706.0 / 872.0  // 81.0%
    private let timerYRatio: CGFloat    = 643.0 / 872.0   // 버튼 top 위 ~28pt

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ── AR 감지 박스 (Figma: 3px solid #36EA45, 화면 중앙)
                Rectangle()
                    .stroke(Color.arBoxStroke, lineWidth: 3)
                    .frame(
                        width:  geometry.size.width  * boxWidthRatio,
                        height: geometry.size.height * boxHeightRatio
                    )
                    .position(
                        x: geometry.size.width  / 2,
                        y: geometry.size.height / 2
                    )

                // ── 비밀번호 텍스트 (Figma: Pretendard Black 40px, white, blur 7.2px)
                Text(lock.password)
                    .font(.custom("Pretendard-Black", size: 40))
                    .foregroundStyle(.white)
                    .blur(radius: isPasswordVisible ? 0 : 7.2)
                    .animation(.easeInOut(duration: 0.3), value: isPasswordVisible)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * passwordYRatio
                    )

                // ── 카운트다운 + 보기/숨기기 버튼
                VStack(spacing: 8) {
                    // 남은 시간
                    Text("\(timeRemaining)초")
                        .font(.custom("Pretendard-Medium", size: 13))
                        .foregroundStyle(.white.opacity(0.7))

                    // 보기/숨기기 버튼 (Figma: 70×70 circle)
                    // 단일 매칭: #958E8B / 복수 매칭: white 40% opacity
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Text(isPasswordVisible ? "숨기기" : "보기")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(
                                isSingleMatch
                                    ? Color.viewButtonSingle
                                    : Color.white.opacity(0.4)
                            )
                            .clipShape(Circle())
                    }
                }
                // VStack 내 버튼 center 기준으로 그룹 전체를 배치
                // VStack 높이 ≈ 13(텍스트) + 8(간격) + 70(버튼) = 91pt → 중심은 상단 + 45.5pt
                // 버튼 center를 buttonCenterYRatio 에 맞추려면 VStack center = buttonCenterYRatio - (91/2 - 35) = - 10.5pt
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * buttonCenterYRatio - 10
                )
            }
        }
        .ignoresSafeArea()
        .onReceive(countdown) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                onDismiss()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PasswordOverlayView(
            lock: DoorLock(category: "도어락", name: "우리집", password: "1234", image: Data()),
            isSingleMatch: true,
            onDismiss: {}
        )
    }
}
