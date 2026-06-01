//
//  PermissionSetupView.swift
//  DoUnlock
//

import SwiftUI

struct PermissionSetupView: View {
    let onRequestPermissions: () -> Void

    // 143°(CSS 기준, 시계방향, 0°=하단) → SwiftUI UnitPoint 변환
    // startPoint ≈ (0.20, 0.90), endPoint ≈ (0.80, 0.10)
    private let iconGradient = LinearGradient(
        colors: [Color.gradientStart, Color.gradientEnd],
        startPoint: UnitPoint(x: 0.20, y: 0.90),
        endPoint: UnitPoint(x: 0.80, y: 0.10)
    )

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // MARK: 앱 헤더
                HStack(spacing: 11) {
                    ZStack {
                        iconGradient
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .frame(width: 39, height: 42)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("DoUnlock")
                        .font(.brandName)
                        .tracking(-0.5)
                        .foregroundStyle(Color.black)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer().frame(height: 32)

                // MARK: 제목 + 부제목
                VStack(alignment: .leading, spacing: 16) {
                    Text("비밀번호를 확인")
                        .font(.heading)
                        .tracking(-0.5)
                        .foregroundStyle(Color.headingText)

                    Text("DoUnlock은 본인 인증을 통해 등록된 집 앞에서만\n도어락 비밀번호를 보여드려요.")
                        .font(.bodyText)
                        .foregroundStyle(Color.secondaryText)
                        .lineSpacing(7) // lineHeight 25 - fontSize 18 = 7
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 32)

                // MARK: 권한 카드
                VStack(spacing: 12) {
                    PermissionCardView(
                        systemImage: "camera",
                        title: "카메라 접근 허용",
                        subtitle: "도어락을 확인하기 위해 필요해요"
                    )

                    PermissionCardView(
                        systemImage: "faceid",
                        title: "Face ID 접근 허용",
                        subtitle: "비밀번호를 본인에게만 보여주기 위해 필요해요"
                    )
                }
                .padding(.horizontal, 16)

                Spacer()

                // MARK: CTA 버튼
                Button(action: onRequestPermissions) {
                    Text("권한 허용하고 시작하기")
                        .font(.button1)
                        .tracking(-0.375)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 53)
                        .background(Color.brandBlue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    PermissionSetupView(onRequestPermissions: {})
}
