//
//  CapturedImageReviewView.swift
//  DoUnlock
//
//  Created by 정필규 on 6/5/26.
//

import SwiftUI

struct CapturedImageReviewView: View {
    @State private var goToRegistration = false

    let image: UIImage

    private let focusWidthRatio: CGFloat = 0.63
    private let focusHeightRatio: CGFloat = 0.45

    var body: some View {
        GeometryReader { geometry in
            let focusWidth = geometry.size.width * focusWidthRatio
            let focusHeight = geometry.size.height * focusHeightRatio


            ZStack {
                // 1. 바깥 배경용: 흐림 + 어둡게
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(Color.black.opacity(0.5))
                    .clipped()
                    .ignoresSafeArea()

                // 2. 중앙 원본 영역용: 같은 이미지를 다시 깔고 네모칸만 보이게 clip
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                    .mask(
                        Rectangle()
                            .frame(width: focusWidth, height: focusHeight)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    )
                    .ignoresSafeArea()
                ZStack{
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.surface.opacity(0.07))
                        .frame(width: 252, height: 64)
                    VStack(alignment: .leading){
                        Text("촬영 완료")
                            .font(Font.buttonLarge)
                            .foregroundStyle(Color.white)
                            .padding(.bottom,4)
                        Text("비밀번호 등록 버튼을 눌러주세요")
                            .font(Font.cardSubtitle)
                            .foregroundStyle(Color.white)
                    }
                    
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 5)

            VStack {

                
                // 3. 네모칸 테두리
                Rectangle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: focusWidth, height: focusHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                
                    VStack{
                        
                        // 4. 버튼
                        Button {
                        } label: {
                            Text("재촬영")
                                .font(Font.button)
                                .frame(maxWidth: .infinity)
                                .frame(height: 53)
                                .background(Color.surface.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(59)
                        }
                        .padding(.bottom, 10)
                        
                        Button {
                            goToRegistration = true
                        } label: {
                            Text("비밀번호 등록하러 가기")
                                .font(Font.button)
                                .frame(maxWidth: .infinity)
                                .frame(height: 53)
                                .background(Color.brandPrimary.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(59)
                        }
                        .navigationDestination(isPresented: $goToRegistration) {
                            DoorLockRegistrationView(
                                imageData: image.jpegData(compressionQuality: 0.8)!
                            )
                        }
                        
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 30)
                
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack{
        CapturedImageReviewView(image: UIImage(named: "photo")!)
    }
}
