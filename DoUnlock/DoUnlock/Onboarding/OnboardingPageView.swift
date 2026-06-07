//
//  OnboardingPageView.swift
//  DoUnlock
//
//  Figma: node-id 160:2145 (1/3), 242:2337 (2/3), 242:2365 (3/3)
//  3단계 온보딩 공통 스캐폴드 — progress bar → 아이콘 → 제목 → 부제 → CTA
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String          // SF Symbol 이름
    let title: String         // \n 포함 가능
    let subtitle: String
    let buttonTitle: String

    static let all: [OnboardingPage] = [
        .init(
            icon: "lock.fill",
            title: "평소에 쓰는 비밀번호,\n잊어버려도 걱정하지 마",
            subtitle: "앱 내 카메라가 잠금 장치를 인식해서 비밀번호를 알려줘요.",
            buttonTitle: "다음"
        ),
        .init(
            icon: "hand.raised.fill",
            title: "사용자의 정보를\n안전하게 보호합니다",
            subtitle: "비밀번호와 개인정보는 사용자의 기기에만 저장되어 오로지 사용자만 접근 가능해요.",
            buttonTitle: "다음"
        ),
        .init(
            icon: "faceid",
            title: "비밀번호는 확인된 순간에만\n보여드려요",
            subtitle: "Face ID 인증 후 비밀번호를 안전하게 표시해요. 안심하세요.",
            buttonTitle: "등록하러 가기"
        ),
    ]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let currentStep: Int      // 0-based
    let totalSteps: Int
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 20) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.brandPrimary : Color.progressTrack)
                            .frame(height: 5)
                    }
                }
                .padding(.top, 50)

                Spacer().frame(height: 60)

                Image(systemName: page.icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.brandPrimary)

                Spacer().frame(height: 24)

                Text(page.title)
                    .textStyle(.displayTitle)
                    .foregroundStyle(Color.textPrimary)

                Spacer().frame(height: 12)

                Text(page.subtitle)
                    .textStyle(.leadBody)
                    .foregroundStyle(Color.textMuted)

                Spacer()

                Button(action: onNext) {
                    Text(page.buttonTitle)
                        .textStyle(.buttonLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 53)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 29)
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.all[1], currentStep: 1, totalSteps: 3, onNext: {})
}
