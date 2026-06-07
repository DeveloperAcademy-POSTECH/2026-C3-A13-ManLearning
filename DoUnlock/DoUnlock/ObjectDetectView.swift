//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import Combine
import SwiftUI
import UIKit

struct CaptureReviewData: Identifiable {
    let id = UUID()
<<<<<<< HEAD:DoUnlock/DoUnlock/ObjectDetectView.swift
    let fullImage: UIImage
    let croppedImage: UIImage
    let boundingBox: CGRect?
=======
    let image: UIImage
>>>>>>> f38d93b561f0bf401fd0c4727c837b4660591bc2:DoUnlock/DoUnlock/ObjectRecongnitionView.swift
}

final class DetectionViewModel: ObservableObject {
    @Published var guideStatus: StrokeColor = .idle
    @Published var latestConfidence: Float? = nil

    private let detector: YOLODetector?
    private let qualityAnalyzer = CropQualityAnalyzer()
    private var isProcessing = false
    private var isDetected = false
    private var detectionStartTime: Date?
    private var lastDetectionTime: Date?
    private var passLostTime: Date?
    private let requiredDetectionDuration: TimeInterval = 3
    private let detectionGracePeriod: TimeInterval = 1
    private let passLostDuration: TimeInterval = 3
    private var errorTimer: Timer?

    init() {
        detector = try? YOLODetector(
            modelName: "custom_yolov8n_doorlock_suitcase",
            labelsName: "custom_class_names"
        )
        scheduleErrorTimeout()
    }

    private func scheduleErrorTimeout() {
        errorTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.guideStatus == .idle else { return }
                self.guideStatus = .error
            }
        }
    }

    func process(pixelBuffer: CVPixelBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        detector?.detect(pixelBuffer: pixelBuffer, minimumConfidence: 0.6) { [weak self] result in
            guard let self else { return }
            let detected: Bool
            let confidence: Float?
            if case .success(let found) = result {
                detected = !found.isEmpty
                confidence = found.first?.confidence
            } else {
                detected = false
                confidence = nil
            }

            DispatchQueue.main.async {
                self.isProcessing = false
                self.isDetected = detected
                self.latestConfidence = confidence
                self.updateStatus()
            }
        }
    }

    private func updateStatus() {
        let now = Date()

        switch guideStatus {
        case .idle:
            if isDetected {
                lastDetectionTime = now
                if detectionStartTime == nil { detectionStartTime = now }
            } else {
                if let last = lastDetectionTime, now.timeIntervalSince(last) > detectionGracePeriod {
                    detectionStartTime = nil
                }
            }
            if let start = detectionStartTime, now.timeIntervalSince(start) >= requiredDetectionDuration {
                guideStatus = .pass
                errorTimer?.invalidate()
                passLostTime = nil
            }

        case .pass:
            if isDetected {
                lastDetectionTime = now
                passLostTime = nil
            } else {
                if let last = lastDetectionTime, now.timeIntervalSince(last) > detectionGracePeriod {
                    if passLostTime == nil { passLostTime = now }
                }
                if let lost = passLostTime, now.timeIntervalSince(lost) >= passLostDuration {
                    guideStatus = .error
                }
            }

        case .error:
            if isDetected {
                lastDetectionTime = now
                detectionStartTime = now
                passLostTime = nil
                guideStatus = .idle
                errorTimer?.invalidate()
                scheduleErrorTimeout()
            }
        }
    }

    func reset() {
        guideStatus = .idle
        isDetected = false
        detectionStartTime = nil
        lastDetectionTime = nil
        passLostTime = nil
        latestConfidence = nil
        qualityAnalyzer.reset()
        errorTimer?.invalidate()
        scheduleErrorTimeout()
    }
}

struct ObjectDetectView: View {
    @StateObject private var viewModel = DetectionViewModel()
    @State private var captureTriggered = false
    @State private var reviewData: CaptureReviewData?

    var body: some View {
        ZStack {
            CameraPreviewView(
                isActive: reviewData == nil,
                captureImageTrigger: captureTriggered,
                pixelHandler: { pixelBuffer, _ in
                    viewModel.process(pixelBuffer: pixelBuffer)
                },
<<<<<<< HEAD:DoUnlock/DoUnlock/ObjectDetectView.swift
                imageHandler: { fullImage, croppedImage in
                    let box = viewModel.latestDetection?.boundingBox
                    DispatchQueue.main.async {
                        reviewData = CaptureReviewData(
                            fullImage: fullImage,
                            croppedImage: croppedImage,
                            boundingBox: box)
=======
                imageHandler: { image in
                    DispatchQueue.main.async {
                        reviewData = CaptureReviewData(image: image)
>>>>>>> f38d93b561f0bf401fd0c4727c837b4660591bc2:DoUnlock/DoUnlock/ObjectRecongnitionView.swift
                    }
                }
            )
            .ignoresSafeArea()

            CameraGuideOverlay(status: $viewModel.guideStatus)
                .ignoresSafeArea()

            // 테스트용 인식률 표시
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.5 + UIScreen.main.bounds.height * 0.45 / 2 + 12)
                if let confidence = viewModel.latestConfidence {
                    Text("인식률: \(Int(confidence * 100))%")
                        .font(.custom("Pretendard-Medium", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                } else {
                    Text("인식률: -")
                        .font(.custom("Pretendard-Medium", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            if viewModel.guideStatus == .pass {
                VStack {
                    Spacer()
                    Button {
                        captureTriggered.toggle()
                    } label: {
                        Text("촬영")
                            .font(.custom("Pretendard-Black", size: 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 53)
                            .background(.white.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.guideStatus == .pass)
        .fullScreenCover(item: $reviewData) { data in
            CapturedImageReviewView(
<<<<<<< HEAD:DoUnlock/DoUnlock/ObjectDetectView.swift
                image: data.fullImage,
                croppedImage: data.croppedImage,
                boundingBox: data.boundingBox,
=======
                image: data.image,
>>>>>>> f38d93b561f0bf401fd0c4727c837b4660591bc2:DoUnlock/DoUnlock/ObjectRecongnitionView.swift
                onRetake: {
                    reviewData = nil
                    viewModel.reset()
                }
            )
        }
    }
}

#Preview {
    ObjectDetectView()
}
