//
//  ObjectDetectView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import Combine
import SwiftUI
import UIKit

struct CaptureReviewData: Identifiable {
    let id = UUID()
    let fullImage: UIImage
    let croppedImage: UIImage
}

final class DetectionViewModel: ObservableObject {
    @Published var guideStatus: StrokeColor = .idle
    @Published var latestConfidence: Float?

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
            } else if let lastDetectionTime,
                      now.timeIntervalSince(lastDetectionTime) > detectionGracePeriod {
                detectionStartTime = nil
            }

            if let detectionStartTime,
               now.timeIntervalSince(detectionStartTime) >= requiredDetectionDuration {
                guideStatus = .pass
                errorTimer?.invalidate()
                passLostTime = nil
            }

        case .pass:
            if isDetected {
                lastDetectionTime = now
                passLostTime = nil
            } else {
                if let lastDetectionTime,
                   now.timeIntervalSince(lastDetectionTime) > detectionGracePeriod,
                   passLostTime == nil {
                    passLostTime = now
                }

                if let passLostTime,
                   now.timeIntervalSince(passLostTime) >= passLostDuration {
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
                imageHandler: { fullImage, croppedImage in
                    DispatchQueue.main.async {
                        reviewData = CaptureReviewData(
                            fullImage: fullImage,
                            croppedImage: croppedImage
                        )
                    }
                }
            )
            .ignoresSafeArea()

            CameraGuideOverlay(status: $viewModel.guideStatus)
                .ignoresSafeArea()

            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.5 + UIScreen.main.bounds.height * 0.45 / 2 + 12)

                Text(confidenceText)
                    .font(.custom("Pretendard-Medium", size: 14))
                    .foregroundColor(viewModel.latestConfidence == nil ? .white.opacity(0.6) : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())

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
            NavigationStack {
                CapturedImageReviewView(
                    image: data.fullImage,
                    croppedImage: data.croppedImage,
                    onRetake: {
                        reviewData = nil
                        viewModel.reset()
                    }
                )
            }
        }
    }

    private var confidenceText: String {
        guard let confidence = viewModel.latestConfidence else { return "인식률: -" }
        return "인식률: \(Int(confidence * 100))%"
    }
}

#Preview {
    ObjectDetectView()
}
