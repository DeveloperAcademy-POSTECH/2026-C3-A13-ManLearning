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
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var dragOffset: CGFloat = 0

    private let pages = OnboardingPage.all
    private let horizontalPadding: CGFloat = 29

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            ZStack {
                Color.screenBg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // 프로그레스 바: 슬라이딩 콘텐츠와 분리되어 상단에 고정, 단계마다 채워짐
                    progressBar
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 50)

                    Spacer().frame(height: 60)

                    // 콘텐츠 + 아래 빈 여백을 한 번에 드래그 영역으로 묶음 (프로그레스 바 ~ 다음 버튼 사이 전체)
                    VStack(spacing: 0) {
                        // 좌우 패딩 없이 화면 끝까지 차지: 전환 중 옆 페이지가 패딩 영역에 가려지지 않음
                        pager(pageWidth: pageWidth)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .gesture(swipeGesture(pageWidth: pageWidth))

                    // 다음 버튼: 콘텐츠가 슬라이드되는 동안에도 위치 고정
                    nextButton
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        HStack(spacing: 20) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.brandPrimary : Color.progressTrack)
                    .frame(height: 5)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    // MARK: - Pager (드래그한 만큼 콘텐츠가 함께 따라 움직이는 슬라이딩 영역)

    private func pager(pageWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(pages.indices, id: \.self) { index in
                pageContent(pages[index])
                    .frame(width: pageWidth, alignment: .leading)
            }
        }
        .offset(x: -CGFloat(currentStep) * pageWidth + dragOffset)
        .frame(width: pageWidth, alignment: .leading)
        .clipped()
        .animation(.easeInOut(duration: 0.32), value: currentStep)
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button(action: handleNext) {
            Text(pages[currentStep].buttonTitle)
                .textStyle(.buttonLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 53)
                .background(Color.brandPrimary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Swipe gesture

    private func swipeGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let translation = value.translation.width
                let isAtFirstPage = currentStep == 0
                let isAtLastPage = currentStep == pages.count - 1

                // 처음/마지막 페이지에서 더 못 넘어가는 방향으로 끌면 고무줄처럼 저항감을 줌
                if (isAtFirstPage && translation > 0) || (isAtLastPage && translation < 0) {
                    dragOffset = translation / 3
                } else {
                    dragOffset = translation
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let threshold = pageWidth / 3

                var targetStep = currentStep
                if translation <= -threshold {
                    targetStep = min(currentStep + 1, pages.count - 1)
                } else if translation >= threshold {
                    targetStep = max(currentStep - 1, 0)
                }

                withAnimation(.easeInOut(duration: 0.32)) {
                    currentStep = targetStep
                    dragOffset = 0
                }
            }
    }

    // MARK: - Navigation

    private func handleNext() {
        if currentStep == pages.count - 1 {
            onComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.32)) {
                currentStep += 1
            }
        }
    }
}

#Preview {
    OnboardingPageView(onComplete: {})
}
