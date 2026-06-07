//
//  DeviceShareSheet.swift
//  DoUnlock
//
//  "주변기기로 공유" 시트. (Figma 466:2417 목록 / 480:3465 전송 완료)
//  도어락 정보 수정 화면 우상단 공유 버튼에서 아래에서 위로 올라옵니다.
//  기기 카드를 탭하면 같은 시트가 "전송 완료" 상태로 전환됩니다(목업).
//
//  ⚠️ 표시 기기는 실제 통신이 아닌 임시(stand-in) 목업입니다.
//  추후 근거리 통신(MultipeerConnectivity 등)을 붙이면 `ShareDevice.sampleData`를
//  실제 탐색된 기기 목록으로 교체하면 됩니다. (DoorLockDraft seam과 같은 패턴)
//

import SwiftUI

struct ShareDevice: Identifiable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension ShareDevice {
    /// 화면 확인용 더미데이터. 실제 근거리 통신 연결 시 제거됩니다.
    static let sampleData: [ShareDevice] = [
        ShareDevice(name: "iPhone 17"),
        ShareDevice(name: "iPhone Air"),
    ]
}

struct DeviceShareSheet: View {
    private let devices: [ShareDevice] = ShareDevice.sampleData
    /// 전송한 기기. nil이면 목록, 값이 있으면 전송 완료 상태.
    /// 실제 통신 미구현 — 탭 즉시 설정하는 목업. 추후 로직 붙일 때 이 설정 지점이 seam.
    @State private var sentDevice: ShareDevice?

    var body: some View {
        VStack(spacing: 0) {
            Text("주변기기로 공유")
                .textStyle(.navTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 20)

            if sentDevice != nil {
                DeviceShareCompleteView()
            } else {
                ScrollView {
                    VStack(spacing: 23) {
                        ForEach(devices) { device in
                            ShareDeviceCard(device: device) {
                                withAnimation { sentDevice = device }
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
    }
}

struct ShareDeviceCard: View {
    let device: ShareDevice
    /// 탭 시 해당 기기로 전송(현재 목업). DoorLockListView의 .buttonStyle(.plain) 패턴과 동일.
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                deviceBadge

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
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
    DeviceShareSheet()
}

#Preview("Complete") {
    DeviceShareCompleteView()
        .background(Color.surface)
}

#Preview("Card") {
    ShareDeviceCard(device: ShareDevice.sampleData[0]) {}
        .padding()
        .background(Color.screenBg)
}
