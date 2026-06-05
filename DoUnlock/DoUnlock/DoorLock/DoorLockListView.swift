//
//  DoorLockListView.swift
//  DoUnlock
//
//  등록된 도어락 목록 화면. (Figma 43:3172)
//

import SwiftUI

struct DoorLockListView: View {
    // 데이터 seam: 추후 팀원 SwiftData 머지 시 `@Query private var locks: [DoorLock]`로 교체.
    @State private var locks: [DoorLockDraft] = DoorLockDraft.sampleData

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("등록된 도어락 목록")
                    .textStyle(.navTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 12)

                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(locks) { lock in
                            NavigationLink {
                                DoorLockRegistrationView(mode: .edit(lock)) { updated in
                                    if let idx = locks.firstIndex(where: { $0.id == updated.id }) {
                                        locks[idx] = updated
                                    }
                                }
                            } label: {
                                DoorLockCard(lock: lock)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }

                registerButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
            }
        }
        // 화면 자체 헤더("등록된 도어락 목록")가 있으므로 NavigationStack 기본 바와 중복 방지.
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sub views

    private var registerButton: some View {
        NavigationLink {
            // 등록(create) 모드. 완료 시 기존 RegistrationCompleteView 플로우 유지.
            DoorLockRegistrationView(mode: .create)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text("새 도어락 등록하기")
                    .textStyle(.buttonLarge)
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(Color.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        Color.infoBorder,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                    )
            )
        }
    }
}

#Preview {
    NavigationStack {
        DoorLockListView()
    }
}
