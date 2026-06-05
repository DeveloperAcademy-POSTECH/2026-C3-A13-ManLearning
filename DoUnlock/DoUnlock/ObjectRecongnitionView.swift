//
//  ObjectRecongnitionView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import Combine
import SwiftUI

final class DetectionViewModel: ObservableObject {
    @Published var detections: [Detection] = []

    private let detector: YOLODetector?
    private var isProcessing = false

    init() {
        detector = try? YOLODetector(
            modelName: "custom_yolov8n_doorlock_suitcase",
            labelsName: "custom_class_names"
        )
    }

    func process(pixelBuffer: CVPixelBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        detector?.detect(pixelBuffer: pixelBuffer, minimumConfidence: 0.4) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if case .success(let found) = result {
                    self?.detections = found
                }
            }
        }
    }
}

struct ObjectRecongnitionView: View {
    @StateObject private var viewModel = DetectionViewModel()

    var body: some View {
        ZStack {
            CameraPreviewView(
                isActive: true,
                captureImageTrigger: false,
                pixelHandler: { pixelBuffer, _ in
                    viewModel.process(pixelBuffer: pixelBuffer)
                },
                imageHandler: { _ in }
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.detections.isEmpty {
                        Text("감지 없음")
                    } else {
                        ForEach(viewModel.detections) { d in
                            Text("\(d.label) \(d.confidencePercent)%")
                        }
                    }
                }
                .padding()
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .padding()
            }
        }
    }
}

#Preview {
    ObjectRecongnitionView()
}
