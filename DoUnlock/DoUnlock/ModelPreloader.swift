//
//  ModelPreloader.swift
//  DoUnlock
//
//  앱 시작(스플래시) 동안 YOLO 모델을 미리 로드해, 스캔 화면 진입 시
//  DetectionViewModel이 다시 로드하지 않고 바로 사용할 수 있도록 합니다.
//

import Foundation

final class ModelPreloader {
    static let shared = ModelPreloader()

    private(set) var detector: YOLODetector?

    private init() {}

    func preload() async {
        guard detector == nil else { return }
        detector = await Task.detached(priority: .userInitiated) {
            try? YOLODetector(
                modelName: "custom_yolov8n_doorlock_suitcase",
                labelsName: "custom_class_names"
            )
        }.value
    }
}
