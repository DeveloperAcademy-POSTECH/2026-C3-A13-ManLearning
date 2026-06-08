//
//  DoorLockListView.swift
//  DoUnlock
//
//  등록된 도어락 목록 화면. (Figma 43:3172)
//

import SwiftUI
import SwiftData

struct DoorLockListView: View {
    // 최근 수정 순으로 정렬. 저장은 SwiftData가 자동 처리.
    @Query(sort: \DoorLock.updateAt, order: .reverse) private var locks: [DoorLock]

    // ==== Nearby ViewModel — 광고(수신측)와 수신 시트 표시를 담당
    @StateObject private var nearbyVM = NearbyViewModel()
    // ==== 수신된 도어락을 SwiftData에 저장하기 위해 modelContext 필요
    @Environment(\.modelContext) private var modelContext
    // 등록 버튼이 scan(카메라) 탭으로 전환하는 데 사용.
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("등록된 도어락 목록")
                    .textStyle(.navTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 38)

                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(locks) { lock in
                            NavigationLink {
                                // DoorLock은 참조 타입 → 수정뷰에서 직접 변경하면 @Query가 자동 반영.
                                // 등록뷰가 자체 NearbyViewModel을 소유하므로 별도 주입 불필요.
                                DoorLockRegistrationView(mode: .edit(lock))
                            } label: {
                                DoorLockCard(lock: lock)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 35)
                    .padding(.bottom, 20)
                }

                registerButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
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
                onAccept: { packet in
                    // ==== NearbyPacket → DoorLock 변환 후 SwiftData에 저장 (DoorLockDraft 제거)
                    let lock = DoorLock(category: packet.category, name: packet.name, password: packet.password, image: Data())
                    modelContext.insert(lock)
                }
            )
            .presentationDetents([.height(490)]) // Figma 박스(484) ≈ 화면 중간, 단일 detent라 더 못 올라감
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sub views

    private var registerButton: some View {
        // 등록은 항상 카메라 촬영을 거친다 → scan(카메라) 탭으로 전환.
        Button {
            router.selectedTab = .scan
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
                        style: StrokeStyle(lineWidth: 1.5, dash: [3])
                    )
            )
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: DoorLock.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(DoorLock(category: "도어락", name: "우리집", password: "1234", image: Data()))
    container.mainContext.insert(DoorLock(category: "자전거", name: "본가", password: "5678", image: Data()))

    return NavigationStack {
        DoorLockListView()
    }
    .modelContainer(container)
    .environment(AppRouter())
}
