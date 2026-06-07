//
//  ShareReceiveSheet.swift
//  DoUnlock
//
//  도어락 정보를 "받는" 쪽 iPhone에서 올라오는 수락 시트. (Figma 544:2697)
//  발신 기기명 + 안내문 + 공유될 도어락 카드 + [나중에 / 공유 허용] 버튼.
//
//  ⚠️ 발신 기기명·도어락 카드는 실제 통신이 아닌 임시(목업) 값입니다.
//  추후 근거리 통신(MultipeerConnectivity 등) 수신부를 붙이면 `senderName`과 카드 내용을
//  실제 수신 데이터로 교체하고, 이 시트를 수신 이벤트에 연결하면 됩니다.
//  (ShareDevice.sampleData seam과 같은 패턴)
//

import SwiftUI

struct ShareReceiveSheet: View {
    /// 공유를 보낸 기기 이름. 실제 수신 연결 전까지는 목업 기본값.
    var senderName: String = "iPhone Air"
    @Environment(\.dismiss) private var dismiss

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
                Text("우리집")
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text("도어락")
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
                dismiss()
            } label: {
                capsuleLabel("나중에", fg: Color.destructiveFg, bg: Color.destructiveBg)
            }

            Button {
                // seam: 추후 수락 시 내 도어락 목록에 추가. 현재는 목업이라 닫기만.
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
    ShareReceiveSheet()
}
