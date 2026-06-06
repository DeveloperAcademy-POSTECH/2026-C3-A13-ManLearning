//
//  CapturedImageReviewView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/5/26.
//

import SwiftUI
import UIKit

struct CapturedImageReviewView: View {
    let image: UIImage
    let boundingBox: CGRect?   // normalized (0-1), origin top-left, from YOLO
    let onRetake: () -> Void

    private let fallbackWidthRatio: CGFloat = 0.63
    private let fallbackHeightRatio: CGFloat = 0.45

    var body: some View {
        GeometryReader { geometry in
            let boxRect = displayRect(for: boundingBox, in: geometry.size)

            ZStack {
                // 1. 배경: 전체 이미지 어둡게
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.55))
                    .ignoresSafeArea()

                // 2. 바운딩 박스 영역만 원본으로 보이게 (마스크)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .mask(
                        Rectangle()
                            .frame(width: boxRect.width, height: boxRect.height)
                            .position(x: boxRect.midX, y: boxRect.midY)
                    )
                    .ignoresSafeArea()

                // 3. 바운딩 박스 테두리
                Rectangle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: boxRect.width, height: boxRect.height)
                    .position(x: boxRect.midX, y: boxRect.midY)

                // 4. 상단 알림 카드
                VStack(alignment: .leading, spacing: 4) {
                    Text("촬영 완료")
                        .font(.custom("Pretendard-SemiBold", size: 18))
                        .foregroundStyle(.white)
                    Text("비밀번호 등록 버튼을 눌러주세요")
                        .font(.custom("Pretendard-Regular", size: 13))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(width: geometry.size.width * fallbackWidthRatio, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .position(
                    x: geometry.size.width / 2,
                    y: boxRect.minY - 56
                )

                // 5. 하단 버튼
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button {
                            onRetake()
                        } label: {
                            Text("재촬영")
                                .font(.custom("Pretendard-SemiBold", size: 15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 53)
                                .background(.white.opacity(0.25))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        Button {
                        } label: {
                            Text("비밀번호 등록하러 가기")
                                .font(.custom("Pretendard-SemiBold", size: 15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 53)
                                .background(Color.brandPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
            }
        }
        .ignoresSafeArea()
    }

    // YOLO normalized box → screen coordinates (accounts for scaledToFill offset)
    private func screenRect(for box: CGRect, in size: CGSize) -> CGRect {
        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else { return fallbackRect(in: size) }
        let scale = max(size.width / imgSize.width, size.height / imgSize.height)
        let scaledW = imgSize.width * scale
        let scaledH = imgSize.height * scale
        let originX = (size.width - scaledW) / 2
        let originY = (size.height - scaledH) / 2
        return CGRect(
            x: originX + box.minX * scaledW,
            y: originY + box.minY * scaledH,
            width: box.width * scaledW,
            height: box.height * scaledH
        )
    }

    private func fallbackRect(in size: CGSize) -> CGRect {
        CGRect(
            x: size.width * (1 - fallbackWidthRatio) / 2,
            y: size.height * (1 - fallbackHeightRatio) / 2,
            width: size.width * fallbackWidthRatio,
            height: size.height * fallbackHeightRatio
        )
    }

    private func displayRect(for box: CGRect?, in size: CGSize) -> CGRect {
        guard let box else { return fallbackRect(in: size) }
        return screenRect(for: box, in: size)
    }
}

#Preview {
    CapturedImageReviewView(
        image: UIImage(named: "photo") ?? UIImage(),
        boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.6, height: 0.4),
        onRetake: {}
    )
}
