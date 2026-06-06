//
//  DeviceShareSheet.swift
//  DoUnlock
//
//  "주변기기로 공유" 시트. (Figma 466:2417)
//  도어락 정보 수정 화면 우상단 공유 버튼에서 아래에서 위로 올라옵니다.
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

    var body: some View {
        VStack(spacing: 0) {
            Text("주변기기로 공유")
                .textStyle(.navTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, 20)

            ScrollView {
                VStack(spacing: 23) {
                    ForEach(devices) { device in
                        ShareDeviceCard(device: device)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface)
    }
}

struct ShareDeviceCard: View {
    let device: ShareDevice

    var body: some View {
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

            // 향후 선택 기기로 전송 동작 연결 자리 (현재 목업).
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

#Preview("Sheet") {
    DeviceShareSheet()
}

#Preview("Card") {
    ShareDeviceCard(device: ShareDevice.sampleData[0])
        .padding()
        .background(Color.screenBg)
}
