//
//  OnboardingIntroView.swift
//  DoUnlock
//
//  Figma: node-id 160:2145 — 온보딩 두 번째 화면 (권한 허용 후 표시)
//

import SwiftUI

struct OnboardingIntroView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 20) {
                    Capsule().fill(Color.brandBlue).frame(height: 5)
                    Capsule().fill(Color.progressInactive).frame(height: 5)
                    Capsule().fill(Color.progressInactive).frame(height: 5)
                }
                .padding(.top, 50)

                Spacer().frame(height: 60)

                Image(systemName: "lock.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.brandBlue)

                Spacer().frame(height: 24)

                Text("평소에 쓰는 비밀번호,\n잊어버려도 걱정하지 마")
                    .textStyle(.introHeading)
                    .foregroundStyle(Color.headingText)

                Spacer().frame(height: 12)

                Text("앱 내 카메라가 잠금 장치를 인식해서 비밀번호를 알려줘요.")
                    .textStyle(.introSubtitle)
                    .foregroundStyle(Color.dimText)

                Spacer()

                Button(action: onNext) {
                    Text("다음")
                        .textStyle(.button1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 53)
                        .background(Color.brandBlue)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 29)
        }
    }
}

#Preview {
    OnboardingIntroView(onNext: {})
}
