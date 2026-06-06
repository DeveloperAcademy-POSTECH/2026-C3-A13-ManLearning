import SwiftUI
import MultipeerConnectivity

// MARK: - View

struct NearbyShareView: View {
    let lock: DoorLock

    @StateObject private var viewModel = NearbyViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHandle
            header
            peerList
            Spacer()
        }
        .background(Color.surface.ignoresSafeArea())
        .onAppear  { viewModel.startSharing(lock: lock) }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Sub views

    // 상단 드래그 핸들
    private var sheetHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.borderDefault)
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var header: some View {
        Text("주변기기로 공유")
            .textStyle(.brandName)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }

    // 탐색된 피어 목록
    @ViewBuilder
    private var peerList: some View {
        if viewModel.nearbyPeers.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("주변 기기 탐색 중...")
                        .textStyle(.caption)
                        .foregroundStyle(Color.textMuted)
                }
                Spacer()
            }
            .padding(.top, 40)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.nearbyPeers, id: \.self) { peer in
                    PeerRowView(
                        peer: peer,
                        didSend: viewModel.sentToPeer == peer
                    )
                    .onTapGesture { viewModel.invitePeer(peer) }

                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
    }
}

// MARK: - Peer Row

struct PeerRowView: View {
    let peer: MCPeerID
    let didSend: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 기기 아이콘
            ZStack {
                Circle()
                    .fill(Color.lockIconStart)
                Image(systemName: "iphone")
                    .foregroundStyle(.white)
                    .font(.system(size: 20))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text(didSend ? "전송 완료" : "도어락 정보 공유")
                    .textStyle(.caption)
                    .foregroundStyle(didSend ? Color.successFg : Color.textMuted)
            }

            Spacer()

            Image(systemName: didSend ? "checkmark" : "chevron.right")
                .foregroundStyle(didSend ? Color.successFg : Color.textMuted)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview {
    NearbyShareView(lock: DoorLock.samples[0])
}
