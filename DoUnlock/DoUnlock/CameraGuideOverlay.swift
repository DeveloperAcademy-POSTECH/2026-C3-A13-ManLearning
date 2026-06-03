//
//  CameraGuideOverlay.swift
//  DoUnlock
//
//  Created by 정필규 on 6/3/26.
//

import SwiftUI

enum strokeColor {
    case defalut
    case error
    case pass
    
    var Color: Color {
        switch self {
        case .defalut: return .white
        case .error: return .red
        case .pass: return .green
        }
    }
}


struct CameraGuideOverlay: View {
    let widthRatio: CGFloat = 0.63
    let heightRatio: CGFloat = 0.45
    @Binding var status : strokeColor

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .stroke(status.Color, lineWidth: 4)
                .frame(
                    width: geometry.size.width * widthRatio,
                    height: geometry.size.height * heightRatio
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CameraGuideOverlay(status: .constant(.defalut))
}
