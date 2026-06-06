//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import Combine
import SwiftUI

final class DetectionViewModel: ObservableObject {
    @Published var guideStatus: StrokeColor = .idle

    private let detector: YOLODetector?
    private let qualityAnalyzer = CropQualityAnalyzer()
    private var isProcessing = false
    private var isStable = false
    private var isDetected = false
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
        // 안정성: 동기 분석 (videoQueue에서 실행)
        let quality = qualityAnalyzer.analyzeCenterCrop(in: pixelBuffer)
        let stable = quality?.passesQualityGate ?? false

        // 객체 감지: 비동기 (프레임 쌓임 방지)
        guard !isProcessing else {
            isStable = stable
            return
        }
        isProcessing = true

        detector?.detect(pixelBuffer: pixelBuffer, minimumConfidence: 0.4) { [weak self] result in
            guard let self else { return }
            let detected: Bool
            if case .success(let found) = result {
                detected = !found.isEmpty
            } else {
                detected = false
            }

            DispatchQueue.main.async {
                self.isProcessing = false
                self.isStable = stable
                self.isDetected = detected
                self.updateStatus()
            }
        }
    }

    private func updateStatus() {
        guard guideStatus == .idle else { return }
        if isDetected && isStable {
            guideStatus = .pass
            errorTimer?.invalidate()
        }
    }

    func reset() {
        guideStatus = .idle
        isDetected = false
        isStable = false
        qualityAnalyzer.reset()
        errorTimer?.invalidate()
        scheduleErrorTimeout()
    }
}

struct ObjectRecongnitionView: View {
    @StateObject private var viewModel = DetectionViewModel()
    @State private var captureTriggered = false

    var body: some View {
        ZStack {
            CameraPreviewView(
                isActive: true,
                captureImageTrigger: captureTriggered,
                pixelHandler: { pixelBuffer, _ in
                    viewModel.process(pixelBuffer: pixelBuffer)
                },
                imageHandler: { _ in }
            )
            .ignoresSafeArea()

            CameraGuideOverlay(status: $viewModel.guideStatus)
                .ignoresSafeArea()

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
    }
}

#Preview {
    ObjectRecongnitionView()
}
