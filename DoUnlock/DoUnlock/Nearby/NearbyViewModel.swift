import Combine
import MultipeerConnectivity
import SwiftUI

// ========================= 전송 패킷 (Codable DTO) =========================

struct NearbyPacket: Codable {
    var category: String
    var name:     String
    var password: String
    var image:    Data?      // 도어락 사진. 옵셔널이라 사진 없는 경우도 안전. JSON에선 base64로 직렬화
}

// ========================= NearbyViewModel =========================

final class NearbyViewModel: ObservableObject {

    // --- 발신측 ---
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var isSendComplete:  Bool        = false

    // --- 수신측 ---
    @Published var receivedLock:     NearbyPacket? = nil   // DoorLockDraft 제거 → NearbyPacket 으로 통일
    @Published var receivedFrom:     String        = ""
    @Published var showReceiveSheet: Bool          = false

    // --- 내부 상태 ---
    private let manager:     NearbyManager = NearbyManager()
    private var pendingLock: NearbyPacket? = nil           // DoorLockDraft 제거
    private var pendingPeer: MCPeerID?     = nil
    // vid(기기 고유값) → 최신 peerID. 같은 기기가 여러 peerID로 광고돼도 한 항목만 표시하기 위한 중복제거 키.
    private var peersByVid:  [String: MCPeerID] = [:]

    // ========================= init =========================

    init() {
        setupCallbacks()
    }

    // ========================= Advertiser (수신측) =========================

    func startAdvertising() {
        manager.startAdvertising()
    }

    func stopAdvertising() {
        manager.stopAdvertising()
    }

    // ========================= Browser (발신측) =========================

    func startBrowsing() {
        discoveredPeers.removeAll()
        peersByVid.removeAll()
        manager.startBrowsing()
    }

    func stopBrowsing() {
        manager.stopBrowsing()
        discoveredPeers.removeAll()
        peersByVid.removeAll()
    }

    // ========================= 전송 =========================

    func sendLock(_ lock: NearbyPacket, to peer: MCPeerID) {   // DoorLockDraft 제거
        pendingLock = lock
        pendingPeer = peer
        // 이미 연결된 경우 바로 전송, 아직 연결 중이면 onPeerConnected 에서 전송
        if manager.session.connectedPeers.contains(peer) {
            sendPendingLock(to: peer)
        }
    }

    // ========================= 수신 처리 =========================

    // "공유 허용" 버튼 — 패킷 반환 후 상태 초기화
    func acceptReceive() -> NearbyPacket? {   // DoorLockDraft 제거
        let lock        = receivedLock
        receivedLock    = nil
        showReceiveSheet = false
        return lock
    }

    // "나중에" 버튼 — 상태 초기화
    func rejectReceive() {
        receivedLock    = nil
        showReceiveSheet = false
    }

    // ========================= 콜백 세팅 =========================

    private func setupCallbacks() {

        // 브라우저: 피어 발견 → vid(기기) 기준 중복제거 후 목록 갱신.
        // 같은 기기가 다른 peerID로 들어와도 한 항목만 유지(최신 peerID로 덮어씀).
        manager.onPeerDiscovered = { [weak self] peer, vid in
            guard let self else { return }
            let key = vid ?? peer.displayName          // vid 없으면 표시 이름으로 대체
            self.peersByVid[key] = peer
            self.rebuildDiscovered()
        }

        // 브라우저: 피어 소실 → 해당 peerID 제거 후 목록 갱신
        manager.onPeerLost = { [weak self] peer in
            guard let self else { return }
            self.peersByVid = self.peersByVid.filter { $0.value != peer }
            self.rebuildDiscovered()
        }

        // 세션: 연결 완료 → 발신측이면 대기 중 전송 실행
        manager.onPeerConnected = { [weak self] peer in
            guard let self else { return }
            if peer == self.pendingPeer {
                self.sendPendingLock(to: peer)
            }
        }

        // 세션: 데이터 수신 → 디코딩 후 수신 시트 표시
        manager.onDataReceived = { [weak self] data, peer in
            guard let self,
                  let packet = try? JSONDecoder().decode(NearbyPacket.self, from: data)
            else { return }

            // DoorLockDraft 제거 — NearbyPacket 그대로 저장
            self.receivedLock     = packet
            self.receivedFrom     = peer.displayName
            self.showReceiveSheet = true
        }
    }

    // ========================= 내부 헬퍼 =========================

    // peersByVid → 표시용 배열로 반영. 이름순 정렬로 표시 순서 안정화.
    private func rebuildDiscovered() {
        discoveredPeers = peersByVid.values.sorted { $0.displayName < $1.displayName }
    }

    private func sendPendingLock(to peer: MCPeerID) {
        guard let packet = pendingLock else { return }   // DoorLockDraft 제거 — 직접 인코딩

        guard let data = try? JSONEncoder().encode(packet) else { return }

        let ok = manager.sendData(data, to: peer)
        if ok {
            isSendComplete = true
        }
        pendingLock = nil
        pendingPeer = nil
    }
}
