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

    #if DEBUG
    // 임시: 수신 시트(ShareReceiveSheet) 검증용. 실제 근거리 통신 수신 로직 붙이면 제거.
    @State private var showReceiveSheet = false
    #endif

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
                                // DoorLock은 참조 타입 → 수정뷰에서 직접 변경하면 @Query가 자동 반영.
                                DoorLockRegistrationView(mode: .edit(lock))
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
            // 임시 검증 트리거. 실제 수신 로직 붙이면 이 블록 통째로 제거.
            Button("수신 시트") { showReceiveSheet = true }
                .font(.caption)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            #endif
        }
        // 화면 자체 헤더("등록된 도어락 목록")가 있으므로 NavigationStack 기본 바와 중복 방지.
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .sheet(isPresented: $showReceiveSheet) {
            ShareReceiveSheet()
                .presentationDetents([.height(490)]) // Figma 박스(484) ≈ 화면 중간, 단일 detent라 더 못 올라감
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    // MARK: - Sub views

    private var registerButton: some View {
        NavigationLink {
            // 등록(create) 모드. 완료 시 기존 RegistrationCompleteView 플로우 유지.
            // imageData는 임시 placeholder — 촬영 플로우(다른 팀원) 연결 시 캡처 이미지 전달로 교체.
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
}
