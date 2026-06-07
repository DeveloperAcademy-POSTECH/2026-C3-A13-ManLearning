//
//  CapturedImageReviewView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/5/26.
//

import SwiftUI
import UIKit

struct CapturedImageReviewView: View {
    @State private var goToRegistration = false
    
    let image: UIImage
    let onRetake: () -> Void

    let widthRatio: CGFloat = 0.63
    let heightRatio: CGFloat = 0.45

    var body: some View {
        GeometryReader { geometry in
            let boxRect = guideRect(in: geometry.size)

            ZStack {
                // 1. 배경: 전체 이미지 어둡게
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.55))
                    .ignoresSafeArea()

                // 2. 가이드 박스 영역만 원본으로 보이게 (마스크)
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

                // 3. 가이드 박스 테두리
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
                .frame(width: geometry.size.width * widthRatio, alignment: .leading)
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
                            goToRegistration = true
                        } label: {
                            Text("비밀번호 등록하러 가기")
                                .font(.custom("Pretendard-SemiBold", size: 15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 53)
                                .background(Color.brandPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .navigationDestination(isPresented: $goToRegistration) {
                                DoorLockRegistrationView(
                                    imageData: image.jpegData(compressionQuality: 0.8)!
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func guideRect(in size: CGSize) -> CGRect {
        CGRect(
            x: size.width * (1 - widthRatio) / 2,
            y: size.height * (1 - heightRatio) / 2,
            width: size.width * widthRatio,
            height: size.height * heightRatio
        )
    }
}

#Preview {
    CapturedImageReviewView(
        image: UIImage(named: "photo") ?? UIImage(),
        onRetake: {}
    )
}
