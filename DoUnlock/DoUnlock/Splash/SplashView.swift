//
//  SplashView.swift
//  DoUnlock
//
//  Figma: node-id 1003:2528 (Hi-Fi / Splash)
//  자물쇠 로고 애니메이션: 한쪽(짧은) 걸쇠가 위로 빠졌다가 다시 잠기는 동작을 무한 반복
//

import SwiftUI

struct SplashView: View {
    @State private var isUnlocked = false

    /// 아이콘을 그리는 정사각 캔버스 한 변의 길이 (Path 좌표는 이 기준)
    private let canvasSize: CGFloat = 44
    /// 짧은 쪽 걸쇠가 위로 빠지는 거리. 긴 쪽 걸쇠는 이보다 더 깊이 박혀있어 계속 잠겨있는 것처럼 보임
    private let shackleLift: CGFloat = 6

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 23) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandGradientStart, Color.brandGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 83, height: 89)

                    lockIcon
                }

                Text("DoUnlock")
                    .font(.custom("Pretendard-Bold", size: 38))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isUnlocked = true
            }
        }
    }

    // MARK: - Lock icon (걸쇠 + 몸통)

    private var lockIcon: some View {
        ZStack {
            // 걸쇠: 위로 살짝 이동하며 한쪽(짧은 다리)만 몸통 밖으로 빠져나감
            shackle
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                .offset(y: isUnlocked ? -shackleLift : 0)

            // 몸통: 걸쇠보다 위에 그려서, 깊게 박힌 쪽 다리는 항상 몸통에 가려져 보임
            lockBody
                .fill(Color.white)
        }
        .frame(width: canvasSize, height: canvasSize)
    }

    /// 비대칭 U자 모양 걸쇠. 왼쪽 다리는 몸통 상단에 닿기만 하고(짧음),
    /// 오른쪽 다리는 몸통 안쪽까지 더 깊이 들어가 있음(긺) → 항상 잠겨 보이는 쪽
    private var shackle: Path {
        Path { path in
            let legXLeft: CGFloat = 14
            let legXRight: CGFloat = 28
            let archCenterY: CGFloat = 15
            let archTopY: CGFloat = 8
            let bodyTopY: CGFloat = 22
            let rightLegBottomY: CGFloat = 30

            path.move(to: CGPoint(x: legXLeft, y: bodyTopY))
            path.addLine(to: CGPoint(x: legXLeft, y: archCenterY))
            path.addCurve(
                to: CGPoint(x: legXRight, y: archCenterY),
                control1: CGPoint(x: legXLeft, y: archTopY),
                control2: CGPoint(x: legXRight, y: archTopY)
            )
            path.addLine(to: CGPoint(x: legXRight, y: rightLegBottomY))
        }
    }

    private var lockBody: some Shape {
        RoundedRectangle(cornerRadius: 5)
            .path(in: CGRect(x: 8, y: 22, width: 26, height: 16))
    }
}

#Preview {
    SplashView()
}
