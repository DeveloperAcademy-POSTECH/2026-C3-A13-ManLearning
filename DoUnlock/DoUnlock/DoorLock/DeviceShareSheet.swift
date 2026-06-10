//
//  DeviceShareSheet.swift
//  DoUnlock
//
//  "주변기기로 공유" 시트. (Figma 466:2417 목록 / 480:3465 전송 완료)
//  도어락 정보 수정 화면 우상단 공유 버튼에서 아래에서 위로 올라옵니다.
//  탐색된 기기 카드를 탭하면 실제 전송 후 "전송 완료" 상태로 전환됩니다.
//
//  실제 근거리 통신(MultipeerConnectivity)이 NearbyViewModel 을 통해 연결됩니다.
//

import MultipeerConnectivity
import SwiftUI

struct DeviceShareSheet: View {
    // ==== 전송할 도어락 패킷 (DoorLockDraft 제거 → NearbyPacket 으로 변경)
    let lock: NearbyPacket
    // ==== Nearby ViewModel (environmentObject 로 주입)
    @EnvironmentObject private var nearbyVM: NearbyViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("주변기기로 공유")
                .textStyle(.navTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 20)

            // ==== isSendComplete 로 완료 상태 전환 (기존 sentDevice 역할)
            if nearbyVM.isSendComplete {
                DeviceShareCompleteView()
            } else {
                ScrollView {
                    VStack(spacing: 23) {
                        // ==== 실제 발견된 피어 목록 표시
                        ForEach(nearbyVM.discoveredPeers, id: \.self) { peer in
                            ShareDeviceCard(peer: peer) {
                                withAnimation { nearbyVM.sendLock(lock, to: peer) }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface)
        // ==== 시트 열릴 때 탐색 시작, 닫힐 때 정리
        .onAppear   { nearbyVM.startBrowsing() }
        .onDisappear {
            nearbyVM.stopBrowsing()
            nearbyVM.isSendComplete = false  // ==== 다음 열기 시 초기화
        }
    }
}

struct ShareDeviceCard: View {
    // ==== MCPeerID 로 변경 (기존 ShareDevice 대체)
    let peer:  MCPeerID
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                deviceBadge

                VStack(alignment: .leading, spacing: 4) {
                    // ==== peer.displayName 사용
                    Text(peer.displayName)
                        .textStyle(.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text("도어락 정보 공유")
                        .textStyle(.cardSubtitle)
                        .foregroundStyle(Color.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.16), radius: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sub views

    private var deviceBadge: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.lockBadgeBg)
            .frame(width: 44, height: 55)
            .overlay {
                Image(systemName: "iphone")
                    .foregroundStyle(Color.lockBadgeIcon)
                    .font(.system(size: 17))
            }
    }
}

// MARK: - 전송 완료

/// 기기 전송 완료 상태. (Figma 480:3465)
/// RegistrationCompleteView.successIcon과 동일한 성공 배지 패턴을 재사용합니다.
struct DeviceShareCompleteView: View {
    var body: some View {
        VStack(spacing: 40) {
            successIcon

            VStack(spacing: 12) {
                Text("전송 완료")
                    .textStyle(.completionTitle)
                    .foregroundStyle(Color.textPrimary)
                Text("상대방의 도어락 목록에 추가되었어요")
                    .textStyle(.subHeading)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimaryTint)
                .frame(width: 120, height: 120)
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 70, height: 70)
            Image(systemName: "checkmark")
                .foregroundStyle(.white)
                .font(.system(size: 24, weight: .bold))
        }
    }
}

#Preview("Sheet") {
    // ==== 프리뷰: 목업 NearbyPacket 사용 (DoorLockDraft 제거)
    DeviceShareSheet(lock: NearbyPacket(category: "도어락", name: "우리집", password: "1234"))
        .environmentObject(NearbyViewModel())
}

#Preview("Complete") {
    DeviceShareCompleteView()
        .background(Color.surface)
}

#Preview("Card") {
    // ==== 프리뷰: MCPeerID 직접 생성
    ShareDeviceCard(peer: MCPeerID(displayName: "iPhone Air")) {}
        .padding()
        .background(Color.screenBg)
}
