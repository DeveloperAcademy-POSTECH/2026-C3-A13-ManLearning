import CoreGraphics
import Foundation

struct Detection: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect

    var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }
}
