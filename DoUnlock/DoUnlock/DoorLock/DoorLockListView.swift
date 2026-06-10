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

    // 스와이프 삭제 시 확인 알럿 대상. nil이 아니면 알럿 표시.
    @State private var lockToDelete: DoorLock?

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("등록된 도어락 목록")
                    .textStyle(.navTitle)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 38)

                List {
                    ForEach(locks) { lock in
                        DoorLockCard(lock: lock)
                            // NavigationLink를 투명하게 카드 뒤에 깔아 탭/네비게이션만 살리고
                            // List가 자동으로 붙이는 오른쪽 disclosure 꺽쇠는 숨김.
                            // DoorLock은 참조 타입 → 수정뷰에서 직접 변경하면 @Query가 자동 반영.
                            // 등록뷰가 자체 NearbyViewModel을 소유하므로 별도 주입 불필요.
                            .background(
                                NavigationLink("") {
                                    DoorLockRegistrationView(mode: .edit(lock))
                                }
                                .opacity(0)
                            )
                        // 커스텀 카드 디자인 유지: 기본 구분선/배경/인셋 제거 후 screenBg 노출.
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        // 옆으로 당겨 삭제 → 즉시 삭제하지 않고 확인 알럿으로 넘김.
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                lockToDelete = lock
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(20)               // 기존 LazyVStack spacing 20 대체
                .scrollContentBackground(.hidden) // List 기본 배경 숨김 → 뒤 screenBg 노출
                .contentMargins(.vertical, 0, for: .scrollContent) // List 자체 상하 인셋 제거
                .padding(.top, 35)                // 원본 LazyVStack top 35와 동일하게 복원

                registerButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
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
                    let lock = DoorLock(category: packet.category, name: packet.name, password: packet.password, image: packet.image ?? Data())
                    modelContext.insert(lock)
                }
            )
            .presentationDetents([.height(490)]) // Figma 박스(484) ≈ 화면 중간, 단일 detent라 더 못 올라감
            .presentationDragIndicator(.visible)
        }
        // ==== 스와이프 삭제 확인. lockToDelete != nil 이면 표시.
        .alert("도어락 삭제", isPresented: Binding(
            get: { lockToDelete != nil },
            set: { if !$0 { lockToDelete = nil } }
        ), presenting: lockToDelete) { lock in
            Button("삭제", role: .destructive) {
                modelContext.delete(lock)  // @Query라 삭제 시 목록 자동 갱신
                lockToDelete = nil
            }
            Button("취소", role: .cancel) { lockToDelete = nil }
        } message: { lock in
            Text("'\(lock.name)'을(를) 삭제할까요? 삭제하면 되돌릴 수 없습니다.")
        }
    }

    // MARK: - Sub views

    private var registerButton: some View {
        Button {
            router.forceRegisterMode = true
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
