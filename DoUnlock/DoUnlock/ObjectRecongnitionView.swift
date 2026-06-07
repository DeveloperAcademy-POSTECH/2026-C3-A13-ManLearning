//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import CoreVideo
import Foundation
import LocalAuthentication // [STEP 1] Face ID를 사용하려면 이 import가 필요합니다
import SwiftUI

// CVPixelBuffer는 카메라 프레임 원본이라 Swift concurrency에서 자동 Sendable로 보지 않습니다.
// 이 뷰에서는 비교 작업을 백그라운드 큐로 넘길 때 한 프레임 단위로만 감싸서 사용합니다.
private struct LiveCameraFrame: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
    let cropRect: CGRect
}

struct ObjectRecongnitionView: View {
    // cameraStatus는 중앙 가이드 프레임 색상입니다.
    // idle: 흰색, error: 빨간색, pass: 초록색
    @State private var cameraStatus: StrokeColor = .idle

    // ObjectSimilarity는 DINO 모델과 mock 이미지 embedding을 들고 있는 비교 기능 객체입니다.
    @State private var objectSimilarity: ObjectSimilarity?

    // DINO와 mock 이미지 준비 상태, 프레임 비교 중복 실행 방지 상태, 최근 결과를 화면에 보여주기 위한 상태들입니다.
    @State private var isPreparingSimilarity = true
    @State private var isComparingFrame = false
    @State private var lastComparisonDate = Date.distantPast
    @State private var latestResult: ObjectSimilarityResult?
    @State private var latestErrorMessage: String?

    // [STEP 2] 상태 변수 3개를 여기에 추가하세요.
    //
    // @State private var isAuthenticating = false
    // → Face ID 팝업이 이미 떠 있는지 여부입니다.
    //   이게 없으면 1초마다 Face ID가 반복 호출됩니다.
    //
    // @State private var isAuthenticated = false
    // → Face ID 인증을 통과했는지 여부입니다.
    //   true가 되면 비밀번호 오버레이를 화면에 보여줍니다.
    //
    // private let testPassword = "1234"
    // → 지금은 저장된 비밀번호가 없으니 테스트용으로 하드코딩합니다.
    //   나중에 실제 저장 데이터로 교체하면 됩니다.

    // 카메라 프레임은 매우 자주 들어오기 때문에 DINO를 매 프레임 돌리지 않고 1초에 한 번만 비교합니다.
    private let comparisonInterval: TimeInterval = 1

    var body: some View {
        ZStack(alignment: .bottom) {
            // CameraPreviewView는 실제 카메라 프리뷰와 중앙 cropRect 계산만 담당합니다.
            // pixelHandler로 넘어오는 cropRect가 화면 중앙 가이드 프레임에 대응하는 영역입니다.
            CameraPreviewView(
                isActive: true,
                captureImageTrigger: false,
                pixelHandler: { pixelBuffer, cropRect in
                    Task { @MainActor in
                        handleFrame(
                            pixelBuffer: pixelBuffer,
                            cropRect: cropRect
                        )
                    }
                },
                imageHandler: { fullImage, croppedImage in
                    // fullImage: 전체 프레임, croppedImage: 화면 중앙 네모칸 영역만 crop된 이미지
                }
            )
            .ignoresSafeArea()

            // 카메라 위에 중앙 가이드 프레임을 얹고, 비교 결과에 따라 색을 바꿉니다.
            CameraGuideOverlay(status: $cameraStatus)
                .ignoresSafeArea()

            // 하단에는 현재 유사도와 가장 유사한 mock 이미지 이름을 보여줍니다.
            similarityStatusView
                .padding(.bottom, 32)

            // [STEP 3] 비밀번호 오버레이를 여기에 추가하세요.
            //
            // if isAuthenticated {
            //     ZStack {
            //         Color.black.opacity(0.6).ignoresSafeArea()  // 반투명 배경
            //         VStack {
            //             Text("비밀번호")
            //             Text(testPassword).font(.largeTitle).bold()
            //             Button("닫기") {
            //                 // 닫으면 인증 상태를 초기화해서 카메라 화면으로 돌아갑니다.
            //                 isAuthenticated = false
            //                 isAuthenticating = false
            //             }
            //         }
            //         .foregroundStyle(.white)
            //     }
            // }
        }
        .task {
            prepareSimilarity()
        }
    }

    private var similarityStatusView: some View {
        Group {
            if isPreparingSimilarity {
                Text("목데이터 준비 중")
            } else if let latestResult {
                VStack(spacing: 3) {
                    Text(
                        "유사도 \(latestResult.score.formatted(.number.precision(.fractionLength(2))))"
                    )

                    if let bestMatchName = latestResult.bestMatchName {
                        Text("가장 유사: \(bestMatchName)")
                            .lineLimit(1)
                    }
                }
            } else if latestErrorMessage != nil {
                Text("목데이터 확인 필요")
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.48), in: Capsule())
    }

    private func prepareSimilarity() {
        do {
            // 화면이 뜰 때 DINO 모델을 로드하고 mock 이미지 embedding을 미리 만들어둡니다.
            // mock 이미지가 Assets.xcassets에 없으면 여기서 에러 상태로 바뀝니다.
            let similarity = try ObjectSimilarity()
            try similarity.prepareMockEmbeddings()

            objectSimilarity = similarity
            isPreparingSimilarity = false
            latestErrorMessage = nil
            cameraStatus = .idle
        } catch {
            objectSimilarity = nil
            isPreparingSimilarity = false
            latestErrorMessage = error.localizedDescription
            cameraStatus = .error

            print("ObjectSimilarity setup failed: \(error.localizedDescription)")
        }
    }

    private func handleFrame(
        pixelBuffer: CVPixelBuffer,
        cropRect: CGRect
    ) {
        // 모델 준비가 끝나지 않았거나 이미 비교 중이면 이번 프레임은 건너뜁니다.
        guard isPreparingSimilarity == false,
              isComparingFrame == false,
              let objectSimilarity
        else {
            return
        }

        // 비교 간격을 제한해서 DINO 추론이 너무 자주 실행되지 않게 합니다.
        let now = Date()
        guard now.timeIntervalSince(lastComparisonDate) >= comparisonInterval else {
            return
        }

        lastComparisonDate = now
        isComparingFrame = true

        let liveFrame = LiveCameraFrame(
            pixelBuffer: pixelBuffer,
            cropRect: cropRect
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 무거운 DINO 추론과 cosine similarity 계산은 백그라운드에서 처리합니다.
                let result = try objectSimilarity.compareLiveFrame(
                    pixelBuffer: liveFrame.pixelBuffer,
                    cropRect: liveFrame.cropRect
                )

                Task { @MainActor in
                    // SwiftUI 상태 변경은 메인 액터에서만 수행합니다.
                    handleComparisonSuccess(result)
                }
            } catch {
                let message = error.localizedDescription

                Task { @MainActor in
                    // 에러도 UI 상태로 보여줘야 하므로 메인 액터에서 반영합니다.
                    handleComparisonFailure(message)
                }
            }
        }
    }

    private func handleComparisonSuccess(
        _ similarityResult: ObjectSimilarityResult
    ) {
        // 비교 성공 시 점수와 가장 비슷한 mock 이미지 이름을 저장하고, 프레임 색상을 갱신합니다.
        isComparingFrame = false
        latestResult = similarityResult
        latestErrorMessage = nil
        cameraStatus = similarityResult.isMatched ? .pass : .error

        if let bestMatchName = similarityResult.bestMatchName {
            print(
                "Best mock match: \(bestMatchName), score: \(similarityResult.score)"
            )
        }

        // [STEP 4] 객체가 인식됐을 때 Face ID를 호출하세요.
        //
        // 조건: isMatched가 true이고, 아직 인증 중이 아니고, 이미 인증된 상태도 아닐 때만 실행합니다.
        // guard similarityResult.isMatched, !isAuthenticating, !isAuthenticated else { return }
        //
        // 그 다음 아래 STEP 5에서 만들 authenticateWithFaceID()를 여기서 호출하면 됩니다.
        // authenticateWithFaceID()
    }

    // [STEP 5] Face ID 인증 함수를 여기에 추가하세요.
    //
    // private func authenticateWithFaceID() {
    //
    //     // 인증 중 상태로 바꿔서 중복 호출을 막습니다.
    //     isAuthenticating = true
    //
    //     let context = LAContext()
    //     var error: NSError?
    //
    //     // 이 기기에서 Face ID를 쓸 수 있는지 먼저 확인합니다.
    //     if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
    //
    //         // Face ID 팝업을 띄웁니다. 결과는 백그라운드 스레드로 옵니다.
    //         context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "잠금을 해제합니다.") { success, _ in
    //             DispatchQueue.main.async {
    //                 if success {
    //                     // 인증 성공 → isAuthenticated를 true로 바꾸면 STEP 3의 오버레이가 나타납니다.
    //                     isAuthenticated = true
    //                 } else {
    //                     // 인증 실패 또는 취소 → 잠금을 풀고 카메라 화면으로 돌아갑니다.
    //                     isAuthenticating = false
    //                 }
    //             }
    //         }
    //
    //     } else {
    //         // Face ID를 아예 쓸 수 없는 기기일 때 (시뮬레이터 포함)
    //         isAuthenticating = false
    //     }
    // }

    private func handleComparisonFailure(_ message: String) {
        // 모델, mock 이미지, crop 변환 중 문제가 생기면 빨간 프레임과 안내 문구로 상태를 보여줍니다.
        isComparingFrame = false
        latestErrorMessage = message
        cameraStatus = .error
        print("ObjectSimilarity compare failed: \(message)")
    }
}


#Preview {
    ObjectRecongnitionView()
}
