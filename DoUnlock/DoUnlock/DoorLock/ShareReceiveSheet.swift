//
//  ShareReceiveSheet.swift
//  DoUnlock
//
//  도어락 정보를 "받는" 쪽 iPhone에서 올라오는 수락 시트. (Figma 544:2697)
//  발신 기기명 + 안내문 + 공유될 도어락 카드 + [나중에 / 공유 허용] 버튼.
//
//  NearbyViewModel 을 통해 실제 수신 데이터를 표시합니다.
//

import SwiftUI

struct ShareReceiveSheet: View {
    // ==== Nearby ViewModel (수신 데이터 + 수락/거절 처리)
    @ObservedObject var nearbyVM: NearbyViewModel
    // ==== 수락 시 도어락을 목록에 추가하는 콜백
    var onAccept: (DoorLockDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    // ==== 실제 수신 데이터 기반 computed 프로퍼티
    private var senderName: String   { nearbyVM.receivedFrom.isEmpty ? "알 수 없음" : nearbyVM.receivedFrom }
    private var lockName:    String   { nearbyVM.receivedLock?.name     ?? "도어락" }
    private var lockCategory: String  { nearbyVM.receivedLock?.category ?? "도어락" }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()                     // 헤더↔카드, 카드↔버튼을 동일 간격으로 벌림 (Figma space-between)
            lockCard
            Spacer()
            buttons
        }
        .padding(.top, 28)                // 시트 상단 여백
        .padding(.horizontal, 15)        // Figma left=15
//        .padding(.bottom, 8)            // 버튼 하단 여백 (홈 인디케이터 위)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
    }

    // MARK: - Sub views

    private var header: some View {
        VStack(spacing: 7) {             // Figma 배지→텍스트 gap=7
            deviceBadge

            VStack(spacing: 12) {        // 이름↔부제 gap=12
                Text(senderName)
                    .textStyle(.completionTitle)
                    .foregroundStyle(Color.textPrimary)
                Text("도어락 정보를 공유하려 합니다")
                    .textStyle(.subHeading)
                    .foregroundStyle(Color.textMuted)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)      // 가운데 정렬 유지
    }

    /// 발신 기기 배지. DeviceShareCompleteView.successIcon과 동일한 ZStack 패턴.
    private var deviceBadge: some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimaryTint)
                .frame(width: 96, height: 96)
            Image(systemName: "iphone")
                .foregroundStyle(Color.brandPrimary)
                .font(.system(size: 40))
        }
    }

    /// 공유될 도어락 카드. RegistrationCompleteView.registeredLockCard와 같은 구성(목업 값).
    private var lockCard: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.lockBadgeBg)
                .frame(width: 44, height: 55)
                .overlay {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.lockBadgeIcon)
                        .font(.system(size: 15))
                }

            VStack(alignment: .leading, spacing: 2) {
                // ==== 실제 수신된 도어락 이름/카테고리 표시
                Text(lockName)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text(lockCategory)
                    .textStyle(.cardSubtitle)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 2)
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            Button {
                // ==== 거절: 상태 초기화 후 닫기
                nearbyVM.rejectReceive()
                dismiss()
            } label: {
                capsuleLabel("나중에", fg: Color.destructiveFg, bg: Color.destructiveBg)
            }

            Button {
                // ==== 수락: 도어락 반환 → 목록에 추가 → 닫기
                if let lock = nearbyVM.acceptReceive() {
                    onAccept(lock)
                }
                dismiss()
            } label: {
                capsuleLabel("공유 허용", fg: .white, bg: Color.brandPrimary)
            }
        }
    }

    private func capsuleLabel(_ text: String, fg: Color, bg: Color) -> some View {
        Text(text)
            .textStyle(.buttonLarge)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(bg)
            .clipShape(Capsule())
    }
}

#Preview {
    // ==== 프리뷰: 목업 VM 으로 확인
    let vm = NearbyViewModel()
    vm.receivedFrom = "iPhone Air"
    vm.receivedLock = DoorLockDraft.sampleData[0]
    return ShareReceiveSheet(nearbyVM: vm, onAccept: { _ in })
}
