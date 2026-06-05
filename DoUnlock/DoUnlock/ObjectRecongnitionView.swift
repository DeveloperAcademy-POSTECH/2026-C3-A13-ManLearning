//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import CoreVideo
import Foundation
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
                imageHandler: { image in
                    // 이 image는 화면 중앙 네모칸 영역만 crop된 이미지
                }
            )
            .ignoresSafeArea()

            // 카메라 위에 중앙 가이드 프레임을 얹고, 비교 결과에 따라 색을 바꿉니다.
            CameraGuideOverlay(status: $cameraStatus)
                .ignoresSafeArea()

            // 하단에는 현재 유사도와 가장 유사한 mock 이미지 이름을 보여줍니다.
            similarityStatusView
                .padding(.bottom, 32)
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
    }

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
