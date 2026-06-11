//
//  CropQualityAnalyzer.swift
//  dounlock_mvp_karl
//
//  Computes early capture-quality signals from the center guide crop.
//

import CoreGraphics
import CoreVideo
import Foundation

struct CropQualityResult: Equatable, Sendable {
    let brightness: Double
    let contrast: Double
    let brightnessScore: Double
    let contrastScore: Double
    let sharpness: Double
    let edgeDensity: Double
    let stability: Double
    let qualityScore: Double
    let passesQualityGate: Bool
    let failedChecks: [String]
    let meanLuma: Double
    let lumaStandardDeviation: Double
    let laplacianMean: Double
    let edgePixelRatio: Double
    let motionDelta: Double?
    let frameSize: CGSize
    let cropRect: CGRect
    let sampledPixelCount: Int

    var brightnessPercentText: String {
        "\(Int((brightness * 100).rounded()))%"
    }

    var contrastPercentText: String {
        "\(Int((contrast * 100).rounded()))%"
    }

    var sharpnessPercentText: String {
        "\(Int((sharpness * 100).rounded()))%"
    }

    var edgeDensityPercentText: String {
        "\(Int((edgeDensity * 100).rounded()))%"
    }

    var stabilityPercentText: String {
        "\(Int((stability * 100).rounded()))%"
    }

    var qualityScoreText: String {
        "\(Int((qualityScore * 100).rounded()))%"
    }

    var gateText: String {
        passesQualityGate ? "Pass" : "Hold"
    }

    var frameSizeText: String {
        "\(Int(frameSize.width)) x \(Int(frameSize.height))"
    }

    var cropSizeText: String {
        "\(Int(cropRect.width)) x \(Int(cropRect.height))"
    }
}

final class CropQualityAnalyzer {
    private let sampleWidth = 72
    private let sampleHeight = 96
    private let stabilityWindowSize = 4
    private var previousSample: [UInt8]?
    private var recentStabilityScores: [Double] = []

    func reset() {
        previousSample = nil
        recentStabilityScores.removeAll()
    }

    func analyzeCenterCrop(in pixelBuffer: CVPixelBuffer) -> CropQualityResult? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        // The camera output is configured as bi-planar YCbCr. The first plane is luma,
        // which is enough for these early quality checks without converting the full frame.
        guard CVPixelBufferGetPlaneCount(pixelBuffer) > 0,
              let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let frameSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        let cropRect = GuideBoxGeometry.pixelRect(in: frameSize)

        let minX = max(0, Int(cropRect.minX.rounded(.down)))
        let minY = max(0, Int(cropRect.minY.rounded(.down)))
        let maxX = min(width, Int(cropRect.maxX.rounded(.up)))
        let maxY = min(height, Int(cropRect.maxY.rounded(.up)))

        guard minX < maxX, minY < maxY else {
            return nil
        }

        let lumaBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let lumaSample = makeLumaSample(
            from: lumaBuffer,
            bytesPerRow: bytesPerRow,
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY
        )

        guard !lumaSample.isEmpty else {
            return nil
        }

        let lumaStats = meanAndStandardDeviation(for: lumaSample)
        let brightness = lumaStats.mean / 255
        let contrast = min(lumaStats.standardDeviation / QualityGateScale.contrastFullScale, 1)
        let sharpnessStats = sharpnessScore(for: lumaSample)
        let edgeStats = edgeDensityScore(for: lumaSample)
        let stabilityStats = updateStability(with: lumaSample)
        let brightnessScore = bandPassScore(
            value: brightness,
            idealRange: QualityGateScale.idealBrightness,
            softRange: QualityGateScale.softBrightness
        )
        let contrastScore = rampScore(
            value: contrast,
            lower: QualityGateScale.minimumUsefulContrast,
            upper: QualityGateScale.strongContrast
        )
        let qualityScore = [
            brightnessScore,
            contrastScore,
            sharpnessStats.score,
            edgeStats.score,
            stabilityStats.score
        ].reduce(0, +) / 5
        let failedChecks = failedQualityChecks(
            brightnessScore: brightnessScore,
            contrastScore: contrastScore,
            sharpness: sharpnessStats.score,
            edgeDensity: edgeStats.score,
            stability: stabilityStats.score,
            qualityScore: qualityScore
        )

        return CropQualityResult(
            brightness: brightness,
            contrast: contrast,
            brightnessScore: brightnessScore,
            contrastScore: contrastScore,
            sharpness: sharpnessStats.score,
            edgeDensity: edgeStats.score,
            stability: stabilityStats.score,
            qualityScore: qualityScore,
            passesQualityGate: failedChecks.isEmpty,
            failedChecks: failedChecks,
            meanLuma: lumaStats.mean,
            lumaStandardDeviation: lumaStats.standardDeviation,
            laplacianMean: sharpnessStats.laplacianMean,
            edgePixelRatio: edgeStats.edgePixelRatio,
            motionDelta: stabilityStats.motionDelta,
            frameSize: frameSize,
            cropRect: CGRect(
                x: CGFloat(minX),
                y: CGFloat(minY),
                width: CGFloat(maxX - minX),
                height: CGFloat(maxY - minY)
            ),
            sampledPixelCount: lumaSample.count
        )
    }

    private func makeLumaSample(
        from lumaBuffer: UnsafePointer<UInt8>,
        bytesPerRow: Int,
        minX: Int,
        minY: Int,
        maxX: Int,
        maxY: Int
    ) -> [UInt8] {
        var sample = Array(repeating: UInt8(0), count: sampleWidth * sampleHeight)
        let cropWidth = maxX - minX
        let cropHeight = maxY - minY

        // Downsample to a fixed grid so sharpness, edge density, and stability use
        // comparable inputs even when the camera output size changes between devices.
        for sampleY in 0..<sampleHeight {
            let sourceY = min(
                maxY - 1,
                minY + Int((Double(sampleY) + 0.5) * Double(cropHeight) / Double(sampleHeight))
            )
            let sourceRow = lumaBuffer + (sourceY * bytesPerRow)

            for sampleX in 0..<sampleWidth {
                let sourceX = min(
                    maxX - 1,
                    minX + Int((Double(sampleX) + 0.5) * Double(cropWidth) / Double(sampleWidth))
                )

                sample[(sampleY * sampleWidth) + sampleX] = sourceRow[sourceX]
            }
        }

        return sample
    }

    private func meanAndStandardDeviation(for sample: [UInt8]) -> (mean: Double, standardDeviation: Double) {
        var sum = 0.0
        var sumSquares = 0.0

        for value in sample {
            let luma = Double(value)
            sum += luma
            sumSquares += luma * luma
        }

        let sampleCount = Double(sample.count)
        let mean = sum / sampleCount
        let variance = max(0, (sumSquares / sampleCount) - (mean * mean))

        return (mean, sqrt(variance))
    }

    private func sharpnessScore(for sample: [UInt8]) -> (score: Double, laplacianMean: Double) {
        guard sampleWidth > 2, sampleHeight > 2 else {
            return (0, 0)
        }

        var laplacianSum = 0.0
        var count = 0

        // A small Laplacian estimate is enough to catch obvious motion blur or
        // defocus. These thresholds are deliberately inspectable and should be
        // tuned with real DoUnlock captures before they become product behavior.
        for y in 1..<(sampleHeight - 1) {
            for x in 1..<(sampleWidth - 1) {
                let index = (y * sampleWidth) + x
                let center = Int(sample[index])
                let left = Int(sample[index - 1])
                let right = Int(sample[index + 1])
                let up = Int(sample[index - sampleWidth])
                let down = Int(sample[index + sampleWidth])
                let laplacian = abs((4 * center) - left - right - up - down)

                laplacianSum += Double(laplacian)
                count += 1
            }
        }

        guard count > 0 else {
            return (0, 0)
        }

        let laplacianMean = laplacianSum / Double(count)
        let score = rampScore(
            value: laplacianMean,
            lower: QualityGateScale.minimumUsefulLaplacian,
            upper: QualityGateScale.sharpLaplacian
        )

        return (score, laplacianMean)
    }

    private func edgeDensityScore(for sample: [UInt8]) -> (score: Double, edgePixelRatio: Double) {
        guard sampleWidth > 1, sampleHeight > 1 else {
            return (0, 0)
        }

        var edgePixelCount = 0
        var totalCount = 0

        for y in 0..<(sampleHeight - 1) {
            for x in 0..<(sampleWidth - 1) {
                let index = (y * sampleWidth) + x
                let center = Int(sample[index])
                let right = Int(sample[index + 1])
                let down = Int(sample[index + sampleWidth])
                let gradient = abs(right - center) + abs(down - center)

                if gradient >= QualityGateScale.edgeGradientThreshold {
                    edgePixelCount += 1
                }

                totalCount += 1
            }
        }

        guard totalCount > 0 else {
            return (0, 0)
        }

        let edgePixelRatio = Double(edgePixelCount) / Double(totalCount)
        let score = rampScore(
            value: edgePixelRatio,
            lower: QualityGateScale.minimumUsefulEdgeRatio,
            upper: QualityGateScale.strongEdgeRatio
        )

        return (score, edgePixelRatio)
    }

    private func updateStability(with sample: [UInt8]) -> (score: Double, motionDelta: Double?) {
        guard let previousSample, previousSample.count == sample.count else {
            previousSample = sample
            recentStabilityScores.removeAll()
            return (0, nil)
        }

        var deltaSum = 0.0

        for index in sample.indices {
            deltaSum += Double(abs(Int(sample[index]) - Int(previousSample[index])))
        }

        let motionDelta = deltaSum / Double(sample.count)
        let immediateScore = 1 - rampScore(
            value: motionDelta,
            lower: QualityGateScale.stableMotionDelta,
            upper: QualityGateScale.unstableMotionDelta
        )

        self.previousSample = sample
        recentStabilityScores.append(immediateScore)

        if recentStabilityScores.count > stabilityWindowSize {
            recentStabilityScores.removeFirst(recentStabilityScores.count - stabilityWindowSize)
        }

        let score = recentStabilityScores.reduce(0, +) / Double(recentStabilityScores.count)
        return (score, motionDelta)
    }

    private func failedQualityChecks(
        brightnessScore: Double,
        contrastScore: Double,
        sharpness: Double,
        edgeDensity: Double,
        stability: Double,
        qualityScore: Double
    ) -> [String] {
        var failures: [String] = []

        if brightnessScore < QualityGateThreshold.minimumBrightnessScore {
            failures.append("brightness")
        }

        if contrastScore < QualityGateThreshold.minimumContrastScore {
            failures.append("contrast")
        }

        if sharpness < QualityGateThreshold.minimumSharpnessScore {
            failures.append("sharpness")
        }

        if edgeDensity < QualityGateThreshold.minimumEdgeDensityScore {
            failures.append("edges")
        }

        if stability < QualityGateThreshold.minimumStabilityScore {
            failures.append("stability")
        }

        if qualityScore < QualityGateThreshold.minimumQualityScore {
            failures.append("score")
        }

        return failures
    }

    private func bandPassScore(
        value: Double,
        idealRange: ClosedRange<Double>,
        softRange: ClosedRange<Double>
    ) -> Double {
        if idealRange.contains(value) {
            return 1
        }

        if value < softRange.lowerBound || value > softRange.upperBound {
            return 0
        }

        if value < idealRange.lowerBound {
            return clamp(
                (value - softRange.lowerBound) / (idealRange.lowerBound - softRange.lowerBound)
            )
        }

        return clamp(
            (softRange.upperBound - value) / (softRange.upperBound - idealRange.upperBound)
        )
    }

    private func rampScore(value: Double, lower: Double, upper: Double) -> Double {
        guard upper > lower else { return value >= upper ? 1 : 0 }
        return clamp((value - lower) / (upper - lower))
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private enum QualityGateScale {
    static let contrastFullScale = 64.0
    static let softBrightness = 0.12...0.95
    static let idealBrightness = 0.28...0.82
    static let minimumUsefulContrast = 0.12
    static let strongContrast = 0.42
    static let minimumUsefulLaplacian = 3.0
    static let sharpLaplacian = 18.0
    static let edgeGradientThreshold = 28
    static let minimumUsefulEdgeRatio = 0.025
    static let strongEdgeRatio = 0.18
    static let stableMotionDelta = 4.0
    static let unstableMotionDelta = 24.0
}

private enum QualityGateThreshold {
    static let minimumBrightnessScore = 0.60
    static let minimumContrastScore = 0.35
    static let minimumSharpnessScore = 0.35
    static let minimumEdgeDensityScore = 0.30
    static let minimumStabilityScore = 0.60
    static let minimumQualityScore = 0.62
}
