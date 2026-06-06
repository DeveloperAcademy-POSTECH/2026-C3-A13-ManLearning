import Foundation
import Combine
import MultipeerConnectivity

// MARK: - ViewModel
// Info.plist에 추가 필요:
//   NSLocalNetworkUsageDescription  → "주변 기기와 도어락 정보를 공유합니다."
//   NSBonjourServices               → "_dounlock-share._tcp"

final class NearbyViewModel: NSObject, ObservableObject {

    // MARK: - Published

    @Published var nearbyPeers: [MCPeerID] = []
    @Published var sentToPeer: MCPeerID? = nil   // 전송 완료된 피어

    // MARK: - Private

    private let serviceType = "dounlock-share"
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var browser: MCNearbyServiceBrowser
    private var advertiser: MCNearbyServiceAdvertiser
    private var lockToSend: DoorLock? = nil

    // MARK: - Init

    override init() {
        myPeerID   = MCPeerID(displayName: UIDevice.current.name)
        session    = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        browser    = MCNearbyServiceBrowser(peer: myPeerID, serviceType: "dounlock-share")
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: "dounlock-share")
        super.init()
        session.delegate    = self
        browser.delegate    = self
        advertiser.delegate = self
    }

    // MARK: - Public

    // 공유 시트가 열릴 때 호출: 탐색 + 광고 시작
    func startSharing(lock: DoorLock) {
        lockToSend = lock
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
    }

    // 공유 시트가 닫힐 때 호출
    func stop() {
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
        nearbyPeers = []
        lockToSend  = nil
        sentToPeer  = nil
    }

    // 사용자가 피어를 탭하면 호출: 초대 → 연결 후 자동 전송
    func invitePeer(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }
}

// MARK: - MCSessionDelegate

extension NearbyViewModel: MCSessionDelegate {

    // 연결 상태 변화 → 연결됐으면 데이터 전송
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard state == .connected else { return }
        guard let lock = lockToSend,
              let data = try? JSONEncoder().encode(lock) else { return }
        try? session.send(data, toPeers: [peerID], with: .reliable)
        DispatchQueue.main.async { self.sentToPeer = peerID }
    }

    // 수신 측: 받은 데이터 처리 (이 앱에서는 공유 시트가 없을 때도 광고하므로 수신 가능)
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let received = try? JSONDecoder().decode(DoorLock.self, from: data) else { return }
        print("NearbyViewModel: 수신된 도어락 - \(received.name)")
        // TODO: 수신된 도어락 저장 로직 연결
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension NearbyViewModel: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.nearbyPeers.contains(peerID) {
                self.nearbyPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("NearbyViewModel: 탐색 오류 - \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension NearbyViewModel: MCNearbyServiceAdvertiserDelegate {

    // 상대방이 초대를 보내면 자동 수락
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("NearbyViewModel: 광고 오류 - \(error.localizedDescription)")
    }
}
