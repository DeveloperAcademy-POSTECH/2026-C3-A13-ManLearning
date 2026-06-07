//
//  DoorLockCard.swift
//  DoUnlock
//
//  등록된 도어락 목록의 카드 셀. (Figma 43:3172 / 52:1323)
//

import SwiftUI

struct DoorLockCard: View {
    let lock: DoorLockDraft

    var body: some View {
        HStack(spacing: 20) {
            lockIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(lock.name)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text(lock.category)
                    .textStyle(.cardSubtitle)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                Text(lock.lastUsedLabel)
                    .textStyle(.cardSubtitle)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 2)
    }

    // MARK: - Sub views

    private var lockIcon: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.lockBadgeBg)
            .frame(width: 44, height: 55)
            .overlay {
                if let uiImage = UIImage(data: lock.image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.lockBadgeIcon)
                        .font(.system(size: 15))
                }
            }
    }
}

#Preview {
    DoorLockCard(lock: DoorLockDraft.sampleData[0])
        .padding()
        .background(Color.screenBg)
}
