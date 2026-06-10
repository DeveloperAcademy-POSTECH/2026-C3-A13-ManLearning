//
//  GuideBoxGeometry.swift
//  dounlock_mvp_karl
//
//  Shared guide box geometry for overlay drawing and frame analysis.
//

import CoreGraphics

enum GuideBoxGeometry {
    static func viewRect(in size: CGSize) -> CGRect {
        guideRect(in: size, maximumWidth: 360)
    }

    static func pixelRect(in size: CGSize) -> CGRect {
        guideRect(in: size, maximumWidth: nil)
    }

    static func marginPixelRect(in size: CGSize, scale: CGFloat = 1.18) -> CGRect {
        let rect = pixelRect(in: size)
        let marginWidth = rect.width * (scale - 1)
        let marginHeight = rect.height * (scale - 1)
        let expandedRect = rect.insetBy(dx: -marginWidth / 2, dy: -marginHeight / 2)

        return expandedRect.intersection(CGRect(origin: .zero, size: size))
    }

    private static func guideRect(in size: CGSize, maximumWidth: CGFloat?) -> CGRect {
        let rawWidth = size.width * 0.72
        let width = min(rawWidth, maximumWidth ?? rawWidth)
        let height = min(width * 1.28, size.height * 0.56)

        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }
}
