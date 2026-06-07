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

    // ==== Nearby ViewModel — 광고(수신측)와 수신 시트 표시를 담당
    @StateObject private var nearbyVM = NearbyViewModel()

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
                                // ==== nearbyVM 을 하위 뷰에 전달 (공유 버튼 연결용)
                                DoorLockRegistrationView(mode: .edit(lock)) { updated in
                                    if let idx = locks.firstIndex(where: { $0.id == updated.id }) {
                                        locks[idx] = updated
                                    }
                                }
                                .environmentObject(nearbyVM)
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

            #if DEBUG
            // ==== 수신 시트 수동 트리거 (디버그 전용)
            Button("수신 시트") { nearbyVM.showReceiveSheet = true }
                .font(.caption)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            #endif
        }
        // 화면 자체 헤더("등록된 도어락 목록")가 있으므로 NavigationStack 기본 바와 중복 방지.
        .toolbar(.hidden, for: .navigationBar)
        // ==== Nearby: 화면 진입 시 광고 시작 (수신측 역할)
        .onAppear   { nearbyVM.startAdvertising() }
        .onDisappear { nearbyVM.stopAdvertising() }
        // ==== Nearby: 데이터 수신 시 수신 시트 표시
        .sheet(isPresented: $nearbyVM.showReceiveSheet, onDismiss: {
            nearbyVM.receivedLock = nil   // 드래그 닫기 시에도 상태 정리
        }) {
            ShareReceiveSheet(
                nearbyVM: nearbyVM,
                onAccept: { newLock in
                    locks.append(newLock) // ==== 수락된 도어락을 목록에 추가
                }
            )
            .presentationDetents([.height(490)]) // Figma 박스(484) ≈ 화면 중간, 단일 detent라 더 못 올라감
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sub views

    private var registerButton: some View {
        NavigationLink {
            // 등록(create) 모드. 완료 시 기존 RegistrationCompleteView 플로우 유지.
            // ==== nearbyVM 전달 (create 모드에서는 공유 버튼 숨김이지만 일관성 유지)
            DoorLockRegistrationView(mode: .create)
                .environmentObject(nearbyVM)
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
