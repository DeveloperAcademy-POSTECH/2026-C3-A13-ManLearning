import CoreGraphics
import CoreML
import Foundation
import Vision

final class YOLODetector {
    private struct Candidate {
        let label: String
        let confidence: Float
        let rect: CGRect
    }

    private let visionModel: VNCoreMLModel
    private let labels: [String]
    private let inferenceQueue: DispatchQueue
    private let inputSize: CGFloat = 640
    private let maxCandidates = 300
    private let maxDetections = 25
    private let iouThreshold: Float = 0.45

    init(modelName: String = "yolov8n_oiv7", labelsName: String = "class_names") throws {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        guard let modelURL = Self.findResource(named: modelName, extensions: ["mlmodelc", "mlpackage"]) else {
            throw DetectorError.modelNotFound(modelName)
        }

        let loadURL: URL
        if modelURL.pathExtension == "mlpackage" {
            loadURL = try MLModel.compileModel(at: modelURL)
        } else {
            loadURL = modelURL
        }

        let model = try MLModel(contentsOf: loadURL, configuration: configuration)
        visionModel = try VNCoreMLModel(for: model)
        labels = Self.loadLabels(named: labelsName)
        guard !labels.isEmpty else {
            throw DetectorError.labelsNotFound(labelsName)
        }
        inferenceQueue = DispatchQueue(label: "com.ada.challenge.yolo.inference.\(modelName)")
    }

    func detect(
        sampleBuffer: CMSampleBuffer,
        minimumConfidence: Float,
        classConfidenceThresholds: [String: Float] = [:],
        completion: @escaping (Result<[Detection], Error>) -> Void
    ) {
        inferenceQueue.async { [weak self] in
            guard let self else { return }

            let request = VNCoreMLRequest(model: self.visionModel)
            request.imageCropAndScaleOption = .scaleFill

            do {
                let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
                try handler.perform([request])

                guard
                    let observation = request.results?.compactMap({ $0 as? VNCoreMLFeatureValueObservation }).first,
                    let multiArray = observation.featureValue.multiArrayValue
                else {
                    throw DetectorError.invalidOutput
                }

                let detections = self.decode(
                    multiArray,
                    minimumConfidence: minimumConfidence,
                    classConfidenceThresholds: classConfidenceThresholds
                )
                completion(.success(detections))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func detect(
        pixelBuffer: CVPixelBuffer,
        minimumConfidence: Float,
        classConfidenceThresholds: [String: Float] = [:],
        completion: @escaping (Result<[Detection], Error>) -> Void
    ) {
        inferenceQueue.async { [weak self] in
            guard let self else { return }

            let request = VNCoreMLRequest(model: self.visionModel)
            request.imageCropAndScaleOption = .scaleFill

            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
                try handler.perform([request])

                guard
                    let observation = request.results?.compactMap({ $0 as? VNCoreMLFeatureValueObservation }).first,
                    let multiArray = observation.featureValue.multiArrayValue
                else {
                    throw DetectorError.invalidOutput
                }

                let detections = self.decode(
                    multiArray,
                    minimumConfidence: minimumConfidence,
                    classConfidenceThresholds: classConfidenceThresholds
                )
                completion(.success(detections))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func decode(
        _ output: MLMultiArray,
        minimumConfidence: Float,
        classConfidenceThresholds: [String: Float]
    ) -> [Detection] {
        let shape = output.shape.map(\.intValue)
        let strides = output.strides.map(\.intValue)
        guard shape.count == 2 || shape.count == 3 else { return [] }

        let hasBatch = shape.count == 3
        let batchOffset = 0
        let firstDim = hasBatch ? shape[1] : shape[0]
        let secondDim = hasBatch ? shape[2] : shape[1]
        let firstStride = hasBatch ? strides[1] : strides[0]
        let secondStride = hasBatch ? strides[2] : strides[1]

        let expectedChannels = labels.count + 4
        let channelsFirst = firstDim == expectedChannels || firstDim < secondDim
        let channelCount = channelsFirst ? firstDim : secondDim
        let anchorCount = channelsFirst ? secondDim : firstDim
        let classCount = min(labels.count, max(0, channelCount - 4))

        guard channelCount >= 5, classCount > 0 else { return [] }

        let candidates: [Candidate]
        switch output.dataType {
        case .float32:
            let pointer = output.dataPointer.bindMemory(to: Float32.self, capacity: output.count)
            candidates = collectCandidates(
                anchorCount: anchorCount,
                classCount: classCount,
                minimumConfidence: minimumConfidence,
                classConfidenceThresholds: classConfidenceThresholds
            ) { channel, anchor in
                let offset = batchOffset + (channelsFirst ? channel * firstStride + anchor * secondStride : anchor * firstStride + channel * secondStride)
                guard output.count > offset else { return 0 }
                return pointer[offset]
            }
        case .float16:
            let pointer = output.dataPointer.bindMemory(to: Float16.self, capacity: output.count)
            candidates = collectCandidates(
                anchorCount: anchorCount,
                classCount: classCount,
                minimumConfidence: minimumConfidence,
                classConfidenceThresholds: classConfidenceThresholds
            ) { channel, anchor in
                let offset = batchOffset + (channelsFirst ? channel * firstStride + anchor * secondStride : anchor * firstStride + channel * secondStride)
                guard output.count > offset else { return 0 }
                return Float(pointer[offset])
            }
        case .double:
            let pointer = output.dataPointer.bindMemory(to: Double.self, capacity: output.count)
            candidates = collectCandidates(
                anchorCount: anchorCount,
                classCount: classCount,
                minimumConfidence: minimumConfidence,
                classConfidenceThresholds: classConfidenceThresholds
            ) { channel, anchor in
                let offset = batchOffset + (channelsFirst ? channel * firstStride + anchor * secondStride : anchor * firstStride + channel * secondStride)
                guard output.count > offset else { return 0 }
                return Float(pointer[offset])
            }
        default:
            return []
        }

        return nonMaximumSuppression(candidates)
            .prefix(maxDetections)
            .map {
                Detection(label: $0.label, confidence: $0.confidence, boundingBox: $0.rect)
            }
    }

    private func collectCandidates(
        anchorCount: Int,
        classCount: Int,
        minimumConfidence: Float,
        classConfidenceThresholds: [String: Float],
        value: (_ channel: Int, _ anchor: Int) -> Float
    ) -> [Candidate] {
        var candidates: [Candidate] = []
        candidates.reserveCapacity(maxCandidates)

        for anchor in 0..<anchorCount {
            var bestClassIndex = 0
            var bestScore: Float = 0

            for classIndex in 0..<classCount {
                let score = value(4 + classIndex, anchor)
                if score > bestScore {
                    bestScore = score
                    bestClassIndex = classIndex
                }
            }

            let label = labels[bestClassIndex]
            let requiredConfidence = max(minimumConfidence, classConfidenceThresholds[label] ?? minimumConfidence)
            guard bestScore >= requiredConfidence else { continue }

            let centerX = CGFloat(value(0, anchor)) / inputSize
            let centerY = CGFloat(value(1, anchor)) / inputSize
            let width = CGFloat(value(2, anchor)) / inputSize
            let height = CGFloat(value(3, anchor)) / inputSize

            let rect = CGRect(
                x: centerX - width / 2,
                y: centerY - height / 2,
                width: width,
                height: height
            ).clampedToUnitSquare

            guard rect.width > 0.01, rect.height > 0.01 else { continue }

            candidates.append(Candidate(
                label: label,
                confidence: bestScore,
                rect: rect
            ))
        }

        return candidates
            .sorted { $0.confidence > $1.confidence }
            .prefix(maxCandidates)
            .map { $0 }
    }

    private func nonMaximumSuppression(_ candidates: [Candidate]) -> [Candidate] {
        var selected: [Candidate] = []

        for candidate in candidates {
            let overlaps = selected.contains { existing in
                intersectionOverUnion(candidate.rect, existing.rect) > iouThreshold
            }
            if !overlaps {
                selected.append(candidate)
            }
        }

        return selected
    }

    private func intersectionOverUnion(_ first: CGRect, _ second: CGRect) -> Float {
        let intersection = first.intersection(second)
        guard !intersection.isNull else { return 0 }

        let intersectionArea = intersection.width * intersection.height
        let unionArea = first.width * first.height + second.width * second.height - intersectionArea
        guard unionArea > 0 else { return 0 }

        return Float(intersectionArea / unionArea)
    }

    private static func loadLabels(named name: String) -> [String] {
        guard let url = findResource(named: name, extensions: ["txt"]) else {
            return []
        }

        let contents = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        return contents
            .split(whereSeparator: \.isNewline)
            .map { String($0) }
    }

    private static func findResource(named name: String, extensions: [String]) -> URL? {
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Models") {
                return url
            }
        }

        guard
            let enumerator = FileManager.default.enumerator(
                at: Bundle.main.bundleURL,
                includingPropertiesForKeys: nil
            )
        else {
            return nil
        }

        for case let url as URL in enumerator {
            guard extensions.contains(url.pathExtension), url.deletingPathExtension().lastPathComponent == name else {
                continue
            }
            return url
        }

        return nil
    }
}

private extension CGRect {
    var clampedToUnitSquare: CGRect {
        let minX = max(0, min(1, origin.x))
        let minY = max(0, min(1, origin.y))
        let maxX = max(0, min(1, origin.x + width))
        let maxY = max(0, min(1, origin.y + height))
        return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
    }
}

enum DetectorError: LocalizedError {
    case modelNotFound(String)
    case labelsNotFound(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "YOLO CoreML model '\(name)' was not found in the app bundle."
        case .labelsNotFound(let name):
            return "YOLO class labels '\(name).txt' were not found in the app bundle."
        case .invalidOutput:
            return "YOLO model returned an unexpected output."
        }
    }
}
