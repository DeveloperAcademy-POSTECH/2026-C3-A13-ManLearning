//
//  PermissionCardView.swift
//  DoUnlock
//

import SwiftUI

struct PermissionCardView: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 42, height: 43)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .textStyle(.cardSubtitle)
                    .foregroundStyle(Color.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 12) {
        PermissionCardView(
            systemImage: "camera",
            title: "카메라 접근 허용",
            subtitle: "잠금장치을 확인하기 위해 필요해요"
        )
        PermissionCardView(
            systemImage: "faceid",
            title: "Face ID 접근 허용",
            subtitle: "비밀번호를 본인에게만 보여주기 위해 필요해요"
        )
    }
    .padding()
    .background(Color.screenBg)
}
