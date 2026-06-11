//
//  ObjectRecognitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import CoreVideo
import Foundation
import LocalAuthentication
import SwiftData
import SwiftUI

private struct LiveCameraFrame: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
    let cropRect: CGRect
}

struct ObjectRecognitionView: View {
    @Query(sort: \DoorLock.updateAt, order: .reverse) private var doorLocks: [DoorLock]

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    @State private var cameraStatus: StrokeColor = .idle
    @State private var objectSimilarity: ObjectSimilarity?
    @State private var isPreparingSimilarity = true
    @State private var hasRegisteredEmbeddings = false
    @State private var isComparingFrame = false
    @State private var lastComparisonDate = Date.distantPast
    @State private var latestResult: ObjectSimilarityResult?
    @State private var latestErrorMessage: String?

    // 인식 → 인증 → 비밀번호 표시 플로우 상태
    @State private var isAuthenticating = false
    @State private var pendingMatches: [MatchEntry] = []
    @State private var showSelectionSheet = false
    @State private var authenticatedLock: DoorLock? = nil
    @State private var isSingleMatchAuth = false

    private let comparisonInterval: TimeInterval = 1

    /// 카메라 세션을 켤 조건. 이 값이 false가 되면 CameraPreviewView가 세션을 멈춰
    /// 카메라 점유(초록 LED)를 해제한다.
    private var isCameraActive: Bool {
        router.selectedTab == .scan
            && scenePhase == .active
            && !router.isDoorLockRegistrationPresented
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(
                isActive: isCameraActive,
                captureImageTrigger: false,
                pixelHandler: { pixelBuffer, cropRect in
                    Task { @MainActor in
                        handleFrame(pixelBuffer: pixelBuffer, cropRect: cropRect)
                    }
                },
                imageHandler: { _, _ in }
            )
            .ignoresSafeArea()

            // 비밀번호 오버레이가 없을 때만 가이드 박스와 상태 표시
            if authenticatedLock == nil {
                CameraGuideOverlay(status: $cameraStatus)
                    .ignoresSafeArea()

                similarityStatusView
                    .padding(.bottom, 32)
            }

            // Face ID 성공 후 비밀번호 오버레이
            if let lock = authenticatedLock {
                PasswordOverlayView(
                    lock: lock,
                    isSingleMatch: isSingleMatchAuth,
                    onDismiss: { authenticatedLock = nil }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authenticatedLock != nil)
        .task(id: registeredLockSignature) {
            prepareSimilarity()
        }
        // 유사한 잠금장치이 2개 이상일 때 선택 시트
        .sheet(isPresented: $showSelectionSheet) {
            DoorLockSelectionSheet(
                matches: pendingMatches,
                doorLocks: doorLocks,
                onAuthenticated: { lock in
                    showSelectionSheet = false
                    isSingleMatchAuth = false
                    authenticatedLock = lock
                }
            )
            .presentationDetents([.medium])
            .presentationCornerRadius(38)
            .presentationDragIndicator(.hidden)
        }
    }

    private var similarityStatusView: some View {
        Group {
            if isPreparingSimilarity, doorLocks.isEmpty == false {
                Text("등록 이미지 준비 중")
            } else if hasRegisteredEmbeddings, let latestResult {
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
                Text("인식 준비 필요")
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.48), in: Capsule())
    }

    private var similarityReferences: [ObjectSimilarityReference] {
        doorLocks.map { lock in
            ObjectSimilarityReference(
                id: lock.id,
                name: lock.name,
                category: lock.category,
                imageData: lock.image
            )
        }
    }

    private var registeredLockSignature: String {
        doorLocks
            .map { lock in
                [
                    lock.id.uuidString,
                    lock.name,
                    lock.category,
                    "\(lock.updateAt.timeIntervalSinceReferenceDate)",
                    "\(lock.image.count)"
                ].joined(separator: ":")
            }
            .joined(separator: "|")
    }

    private func prepareSimilarity() {
        let references = similarityReferences

        guard references.isEmpty == false else {
            objectSimilarity = nil
            isPreparingSimilarity = false
            hasRegisteredEmbeddings = false
            latestResult = nil
            latestErrorMessage = nil
            cameraStatus = .error
            return
        }

        isPreparingSimilarity = true
        hasRegisteredEmbeddings = false
        latestResult = nil
        latestErrorMessage = nil

        do {
            let similarity = try ObjectSimilarity()
            try similarity.prepareRegisteredEmbeddings(from: references)

            objectSimilarity = similarity
            hasRegisteredEmbeddings = similarity.hasRegisteredEmbeddings
            isPreparingSimilarity = false
            latestErrorMessage = nil
            cameraStatus = similarity.hasRegisteredEmbeddings ? .idle : .error
        } catch {
            objectSimilarity = nil
            hasRegisteredEmbeddings = false
            isPreparingSimilarity = false
            latestErrorMessage = error.localizedDescription
            cameraStatus = .error

            print("ObjectSimilarity setup failed: \(error.localizedDescription)")
        }
    }

    private func handleFrame(pixelBuffer: CVPixelBuffer, cropRect: CGRect) {
        guard isPreparingSimilarity == false,
              isComparingFrame == false,
              hasRegisteredEmbeddings,
              let objectSimilarity
        else { return }

        // 비밀번호 표시 중이거나 인증 진행 중이거나 선택 시트가 열려 있으면 비교 중단
        guard authenticatedLock == nil, !isAuthenticating, !showSelectionSheet else { return }

        let now = Date()
        guard now.timeIntervalSince(lastComparisonDate) >= comparisonInterval else { return }

        lastComparisonDate = now
        isComparingFrame = true

        let liveFrame = LiveCameraFrame(pixelBuffer: pixelBuffer, cropRect: cropRect)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try objectSimilarity.compareLiveFrame(
                    pixelBuffer: liveFrame.pixelBuffer,
                    cropRect: liveFrame.cropRect
                )

                Task { @MainActor in
                    handleComparisonSuccess(result)
                }
            } catch {
                let message = error.localizedDescription

                Task { @MainActor in
                    handleComparisonFailure(message)
                }
            }
        }
    }

    private func handleComparisonSuccess(_ result: ObjectSimilarityResult) {
        isComparingFrame = false
        latestResult = result
        latestErrorMessage = nil
        cameraStatus = result.isMatched ? .pass : .error

        if let bestMatchName = result.bestMatchName {
            print("Best match: \(bestMatchName), score: \(result.score)")
        }

        guard result.isMatched, !isAuthenticating, !showSelectionSheet, authenticatedLock == nil else { return }

        let matches = result.allMatches
        guard !matches.isEmpty else { return }

        if matches.count == 1,
           let match = matches.first,
           let lock = doorLocks.first(where: { $0.id == match.id }) {
            isAuthenticating = true
            authenticateWithFaceID(for: lock, isSingle: true)
        } else if matches.count >= 2 {
            pendingMatches = matches
            showSelectionSheet = true
        }
    }

    private func authenticateWithFaceID(for lock: DoorLock, isSingle: Bool) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "잠금을 해제합니다."
            ) { success, _ in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        isSingleMatchAuth = isSingle
                        authenticatedLock = lock
                    }
                }
            }
        } else {
            isAuthenticating = false
        }
    }

    private func handleComparisonFailure(_ message: String) {
        isComparingFrame = false
        latestErrorMessage = message
        cameraStatus = .error
        print("ObjectSimilarity compare failed: \(message)")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: DoorLock.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    return ObjectRecognitionView()
        .modelContainer(container)
}
