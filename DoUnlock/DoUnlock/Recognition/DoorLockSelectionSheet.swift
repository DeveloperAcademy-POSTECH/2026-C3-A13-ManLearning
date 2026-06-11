//
//  DoorLockSelectionSheet.swift
//  DoUnlock
//
//  유사한 잠금장치이 2개 이상일 때 나타나는 선택 시트.
//  항목을 탭하면 Face ID를 수행하고, 성공 시 onAuthenticated 콜백을 호출한다.
//

import LocalAuthentication
import SwiftUI

struct DoorLockSelectionSheet: View {
    let matches: [MatchEntry]
    let doorLocks: [DoorLock]
    let onAuthenticated: (DoorLock) -> Void

    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                        if let lock = lock(for: match) {
                            Button {
                                authenticate(for: lock)
                            } label: {
                                lockRow(lock: lock)
                            }
                            .buttonStyle(.plain)
                            .disabled(isAuthenticating)

                            if index < matches.count - 1 {
                                Divider()
                                    .background(Color.borderDefault)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(Color.surface)
    }

    // MARK: - Sub views

    private var sheetHeader: some View {
        VStack(spacing: 0) {
            // 그래버 (Figma: 36×5, #CCCCCC, border-radius 100px)
            RoundedRectangle(cornerRadius: 100)
                .fill(Color.grabberFill)
                .frame(width: 36, height: 5)
                .padding(.top, 5)
                .padding(.bottom, 11)

            // 타이틀 영역 (Figma: 44px height, Pretendard Bold 20px, #1A1A1A)
            Text("유사한 잠금장치 선택")
                .font(.navTitle)
                .foregroundStyle(Color.textPrimary)
                .frame(height: 44)
        }
    }

    private func lockRow(lock: DoorLock) -> some View {
        HStack(spacing: 12) {
            lockThumbnail(lock: lock)

            VStack(alignment: .leading, spacing: 2) {
                Text(lock.name)
                    .font(.custom("Pretendard-Regular", size: 17))
                    .foregroundStyle(Color.textPrimary)
                Text(lock.category)
                    .font(.custom("Pretendard-Regular", size: 13))
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }

    private func lockThumbnail(lock: DoorLock) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.lockBadgeBg)
            .frame(width: 36, height: 44)
            .overlay {
                if let uiImage = UIImage(data: lock.image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.lockBadgeIcon)
                        .font(.system(size: 13))
                }
            }
    }

    // MARK: - Helpers

    private func lock(for match: MatchEntry) -> DoorLock? {
        doorLocks.first { $0.id == match.id }
    }

    private func authenticate(for lock: DoorLock) {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "잠금을 해제합니다."
            ) { success, _ in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        onAuthenticated(lock)
                    }
                }
            }
        } else {
            isAuthenticating = false
        }
    }
}

#Preview {
    let locks = [
        DoorLock(category: "잠금장치", name: "우리집 현관", password: "1234", image: Data()),
        DoorLock(category: "잠금장치", name: "사무실 입구", password: "5678", image: Data()),
    ]
    let matches = locks.map { MatchEntry(id: $0.id, name: $0.name, category: $0.category, score: 0.85) }

    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            DoorLockSelectionSheet(
                matches: matches,
                doorLocks: locks,
                onAuthenticated: { _ in }
            )
            .presentationDetents([.medium])
            .presentationCornerRadius(38)
            .presentationDragIndicator(.hidden)
        }
}
