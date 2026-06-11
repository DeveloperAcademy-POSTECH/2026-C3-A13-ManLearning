//
//  ObjectSimilarity.swift
//  DoUnlock
//
//  Created by Codex on 6/5/26.
//

import CoreImage
import CoreML
import Foundation
import UIKit

struct ObjectSimilarityReference: Sendable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let imageData: Data
}

struct MatchEntry: Sendable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let score: Float
}

struct ObjectSimilarityResult: Sendable {
    // score: 라이브 카메라 프레임과 저장 이미지 중 가장 가까운 이미지의 cosine similarity 값입니다.
    // isMatched: score가 threshold 이상인지 여부이며, 화면의 초록/빨강 프레임 상태에 사용합니다.
    // bestMatchID/name/category: 가장 유사한 저장 잠금장치 정보입니다.
    // allMatches: threshold 이상인 모든 매칭 항목 (score 내림차순).
    let score: Float
    let isMatched: Bool
    let bestMatchID: UUID?
    let bestMatchName: String?
    let bestMatchCategory: String?
    let allMatches: [MatchEntry]
}

enum ObjectSimilarityError: LocalizedError, Sendable {
    case modelNotFound
    case invalidImage
    case invalidCropRect
    case cannotCreatePixelBuffer
    case missingOutput(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "DINOv3SmallFeatureExtractor model was not found in the app bundle."
        case .invalidImage:
            return "The source image could not be converted into a Core Image input."
        case .invalidCropRect:
            return "The camera crop rect is outside the pixel buffer bounds."
        case .cannotCreatePixelBuffer:
            return "The 224x224 model input pixel buffer could not be created."
        case .missingOutput(let outputName):
            return "The model output named \(outputName) was not found."
        }
    }
}

final class ObjectSimilarity: @unchecked Sendable {
    private struct RegisteredEmbedding {
        let id: UUID
        let name: String
        let category: String
        let values: [Float]
    }

    private let modelName = "DINOv3SmallFeatureExtractor"
    private let inputName = "image"
    private let outputName = "embedding"
    private let inputSize = 224
    private let threshold: Float
    private let model: MLModel
    private let ciContext = CIContext()

    // 저장 이미지는 매 프레임마다 다시 DINO에 넣지 않고, 처음 한 번 embedding으로 변환해 캐싱합니다.
    private var registeredEmbeddings: [RegisteredEmbedding] = []

    var hasRegisteredEmbeddings: Bool {
        registeredEmbeddings.isEmpty == false
    }

    init(threshold: Float = 0.7) throws {
        self.threshold = threshold
        self.model = try Self.loadModel(named: modelName)
    }

    func prepareRegisteredEmbeddings(
        from references: [ObjectSimilarityReference]
    ) throws {
        var embeddings: [RegisteredEmbedding] = []

        for reference in references {
            guard let image = UIImage(data: reference.imageData) else {
                print("Skipping invalid registered image data: \(reference.id)")
                continue
            }

            // DINO는 이미지를 embedding vector로 바꿔주는 feature extractor입니다.
            // 이 단계에서 저장 사진들을 미리 vector로 바꿔두면 라이브 비교가 훨씬 가벼워집니다.
            do {
                let embedding = try extractEmbedding(from: image)
                embeddings.append(
                    RegisteredEmbedding(
                        id: reference.id,
                        name: reference.name,
                        category: reference.category,
                        values: embedding
                    )
                )
            } catch ObjectSimilarityError.invalidImage {
                print("Skipping invalid registered image: \(reference.id)")
            } catch {
                throw error
            }
        }

        registeredEmbeddings = embeddings
    }

    func compareLiveFrame(
        pixelBuffer: CVPixelBuffer,
        cropRect: CGRect
    ) throws -> ObjectSimilarityResult {
        guard registeredEmbeddings.isEmpty == false else {
            return ObjectSimilarityResult(
                score: 0,
                isMatched: false,
                bestMatchID: nil,
                bestMatchName: nil,
                bestMatchCategory: nil,
                allMatches: []
            )
        }

        // CameraPreviewView가 넘겨준 cropRect는 화면 중앙 가이드 프레임에 해당하는 카메라 픽셀 영역입니다.
        // 전체 카메라 화면이 아니라 이 영역만 DINO에 넣어 현재 물체의 embedding을 뽑습니다.
        let liveEmbedding = try extractEmbedding(
            from: pixelBuffer,
            cropRect: cropRect
        )

        // 저장된 사진 여러 장 모두의 cosine similarity를 계산합니다.
        let scored = registeredEmbeddings.map { reg in
            MatchEntry(
                id: reg.id,
                name: reg.name,
                category: reg.category,
                score: Self.cosineSimilarity(liveEmbedding, reg.values)
            )
        }

        let bestMatch = scored.max { $0.score < $1.score }
        let score = bestMatch?.score ?? 0
        // threshold 이상인 항목을 모두 모아 score 내림차순으로 정렬합니다.
        let allMatches = scored.filter { $0.score >= threshold }.sorted { $0.score > $1.score }

        return ObjectSimilarityResult(
            score: score,
            isMatched: score >= threshold,
            bestMatchID: bestMatch?.id,
            bestMatchName: bestMatch?.name,
            bestMatchCategory: bestMatch?.category,
            allMatches: allMatches
        )
    }

    private static func loadModel(named modelName: String) throws -> MLModel {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        // Xcode가 모델을 앱에 포함할 때는 보통 .mlmodelc로 컴파일됩니다.
        if let compiledModelURL = Bundle.main.url(
            forResource: modelName,
            withExtension: "mlmodelc"
        ) {
            return try MLModel(
                contentsOf: compiledModelURL,
                configuration: configuration
            )
        }

        // 개발 중 .mlpackage가 bundle에 직접 들어오는 경우도 대비해 런타임 컴파일 fallback을 둡니다.
        if let packageURL = Bundle.main.url(
            forResource: modelName,
            withExtension: "mlpackage"
        ) {
            let compiledModelURL = try MLModel.compileModel(at: packageURL)
            return try MLModel(
                contentsOf: compiledModelURL,
                configuration: configuration
            )
        }

        throw ObjectSimilarityError.modelNotFound
    }

    private func extractEmbedding(
        from image: UIImage
    ) throws -> [Float] {
        guard let ciImage = CIImage(image: image) else {
            throw ObjectSimilarityError.invalidImage
        }

        // 저장 이미지는 전체 사진을 모델 입력으로 사용합니다.
        let inputPixelBuffer = try makeModelInputPixelBuffer(
            from: ciImage,
            cropRect: ciImage.extent
        )

        return try predictEmbedding(from: inputPixelBuffer)
    }

    private func extractEmbedding(
        from pixelBuffer: CVPixelBuffer,
        cropRect: CGRect
    ) throws -> [Float] {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // 라이브 카메라는 중앙 가이드 프레임 영역만 잘라서 모델 입력으로 사용합니다.
        let inputPixelBuffer = try makeModelInputPixelBuffer(
            from: ciImage,
            cropRect: cropRect
        )

        return try predictEmbedding(from: inputPixelBuffer)
    }

    private func makeModelInputPixelBuffer(
        from image: CIImage,
        cropRect: CGRect
    ) throws -> CVPixelBuffer {
        // cropRect가 이미지 밖으로 살짝 벗어날 수 있어서 실제 이미지 영역과 교차시킨 안전한 rect를 만듭니다.
        let safeCropRect = cropRect
            .intersection(image.extent)
            .integral

        guard safeCropRect.width > 0, safeCropRect.height > 0 else {
            throw ObjectSimilarityError.invalidCropRect
        }

        var inputPixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]

        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            inputSize,
            inputSize,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &inputPixelBuffer
        )

        guard result == kCVReturnSuccess, let inputPixelBuffer else {
            throw ObjectSimilarityError.cannotCreatePixelBuffer
        }

        // DINO 모델 입력은 224x224 image입니다.
        // 선택된 영역을 원점으로 옮긴 뒤 224x224에 맞게 resize해서 CoreML 입력 pixel buffer에 렌더링합니다.
        let croppedImage = image
            .cropped(to: safeCropRect)
            .transformed(
                by: CGAffineTransform(
                    translationX: -safeCropRect.minX,
                    y: -safeCropRect.minY
                )
            )
            .transformed(
                by: CGAffineTransform(
                    scaleX: CGFloat(inputSize) / safeCropRect.width,
                    y: CGFloat(inputSize) / safeCropRect.height
                )
            )

        ciContext.render(
            croppedImage,
            to: inputPixelBuffer,
            bounds: CGRect(
                x: 0,
                y: 0,
                width: inputSize,
                height: inputSize
            ),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return inputPixelBuffer
    }

    private func predictEmbedding(
        from pixelBuffer: CVPixelBuffer
    ) throws -> [Float] {
        // 모델의 input/output 이름은 FeatureDescriptions.json 기준으로 image / embedding입니다.
        let featureProvider = try MLDictionaryFeatureProvider(
            dictionary: [
                inputName: MLFeatureValue(pixelBuffer: pixelBuffer)
            ]
        )

        let output = try model.prediction(from: featureProvider)

        guard let embedding = output
            .featureValue(for: outputName)?
            .multiArrayValue
        else {
            throw ObjectSimilarityError.missingOutput(outputName)
        }

        return embedding.floatValues()
    }

    private static func cosineSimilarity(
        _ lhs: [Float],
        _ rhs: [Float]
    ) -> Float {
        // cosine similarity는 두 embedding vector의 방향이 얼마나 비슷한지 보는 값입니다.
        // 1에 가까울수록 두 이미지가 DINO feature 공간에서 비슷하다고 볼 수 있습니다.
        let count = min(lhs.count, rhs.count)
        guard count > 0 else { return 0 }

        var dotProduct: Float = 0
        var lhsMagnitude: Float = 0
        var rhsMagnitude: Float = 0

        for index in 0..<count {
            let lhsValue = lhs[index]
            let rhsValue = rhs[index]

            dotProduct += lhsValue * rhsValue
            lhsMagnitude += lhsValue * lhsValue
            rhsMagnitude += rhsValue * rhsValue
        }

        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }

        return dotProduct / (sqrt(lhsMagnitude) * sqrt(rhsMagnitude))
    }
}

private extension MLMultiArray {
    func floatValues() -> [Float] {
        var values: [Float] = []
        values.reserveCapacity(count)

        for index in 0..<count {
            values.append(Float(truncating: self[index]))
        }

        return values
    }
}
