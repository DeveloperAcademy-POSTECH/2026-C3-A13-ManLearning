import MultipeerConnectivity
import UIKit

// ========================= 상수 =========================

private let kServiceType = "dounlock-share"   // 15자 이하, [a-z0-9\-] 만 허용

// ========================= 콜백 타입 (C 함수 포인터 대체) =========================

typealias NearbyPeerDiscoveredCallback  = (_ peer: MCPeerID) -> Void
typealias NearbyPeerLostCallback        = (_ peer: MCPeerID) -> Void
typealias NearbyPeerConnectedCallback   = (_ peer: MCPeerID) -> Void
typealias NearbyDataReceivedCallback    = (_ data: Data, _ from: MCPeerID) -> Void

// ========================= NearbyManager =========================

final class NearbyManager: NSObject {

    // --- 상태 ---
    private(set) var localPeerID: MCPeerID
    private(set) var session:     MCSession
    private var advertiser:       MCNearbyServiceAdvertiser?
    private var browser:          MCNearbyServiceBrowser?

    // 같은 기기 식별용. 목록(광고)·등록뷰(탐색)가 각자 NearbyManager 인스턴스라 MCPeerID로는
    // 자기 자신을 구분 못 함 → 벤더 식별자를 광고 정보로 실어 보내 탐색 측에서 자기 광고를 거른다.
    private let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? ""

    // --- 콜백 (ViewModel 이 세팅) ---
    var onPeerDiscovered: NearbyPeerDiscoveredCallback?
    var onPeerLost:       NearbyPeerLostCallback?
    var onPeerConnected:  NearbyPeerConnectedCallback?
    var onDataReceived:   NearbyDataReceivedCallback?

    // ========================= init =========================

    override init() {
        localPeerID = MCPeerID(displayName: UIDevice.current.name)
        session     = MCSession(peer: localPeerID,
                                securityIdentity: nil,
                                encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    // ========================= Advertiser (수신측: 내 존재를 광고) =========================

    func startAdvertising() {
        let adv = MCNearbyServiceAdvertiser(peer: localPeerID,
                                            discoveryInfo: ["vid": vendorID],
                                            serviceType: kServiceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
    }

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    // ========================= Browser (발신측: 주변 기기 탐색) =========================

    func startBrowsing() {
        let br = MCNearbyServiceBrowser(peer: localPeerID,
                                        serviceType: kServiceType)
        br.delegate = self
        br.startBrowsingForPeers()
        browser = br
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    // ========================= 연결 요청 =========================

    func invitePeer(_ peer: MCPeerID) {
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }

    // ========================= 데이터 전송 =========================

    // 반환값: 전송 성공 여부 (C 스타일 bool return)
    @discardableResult
    func sendData(_ data: Data, to peer: MCPeerID) -> Bool {
        do {
            try session.send(data, toPeers: [peer], with: .reliable)
            return true
        } catch {
            return false
        }
    }

    // ========================= 연결 해제 =========================

    func disconnect() {
        session.disconnect()
        stopAdvertising()
        stopBrowsing()
    }
}

// ========================= MCSessionDelegate =========================

extension NearbyManager: MCSessionDelegate {

    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        if state == .connected {
            DispatchQueue.main.async { self.onPeerConnected?(peerID) }
        }
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.onDataReceived?(data, peerID) }
    }

    // 사용 안 함 — 프로토콜 필수 구현
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}
}

// ========================= MCNearbyServiceAdvertiserDelegate =========================

extension NearbyManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 자동 수락
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {}
}

// ========================= MCNearbyServiceBrowserDelegate =========================

extension NearbyManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        // 같은 기기(벤더 식별자 동일)의 자기 광고는 제외 — 자신에게 전송되는 것 방지.
        guard info?["vid"] != vendorID else { return }
        // 발견 즉시 초대 — 연결 성립 후 onPeerConnected 에서 데이터 전송
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        DispatchQueue.main.async { self.onPeerDiscovered?(peerID) }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.onPeerLost?(peerID) }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {}
}
