//
//  RegistrationFlowView.swift
//  DoUnlock
//
//  새 잠금장치 등록 플로우의 단일 NavigationStack 루트.
//

import SwiftUI

struct RegistrationFlowView: View {
    @Environment(AppRouter.self) private var router
    @State private var capturedData: CaptureReviewData?
    @State private var isReviewPresented = false

    var body: some View {
        NavigationStack {
            ObjectDetectView(
                isActive: !isReviewPresented,
                onCapture: { data in
                    capturedData = data
                    isReviewPresented = true
                },
                onClose: {
                    finishRegistrationFlow(to: .password)
                }
            )
            .navigationDestination(isPresented: $isReviewPresented) {
                if let capturedData {
                    CapturedImageReviewView(
                        image: capturedData.fullImage,
                        croppedImage: capturedData.croppedImage,
                        onRetake: {
                            self.capturedData = nil
                            isReviewPresented = false
                        }
                    )
                }
            }
        }
        .onChange(of: router.finishCaptureFlowRequested) { _, requested in
            guard requested else { return }
            finishRegistrationFlow(to: .password)
            router.finishCaptureFlowRequested = false
        }
        .onChange(of: router.finishCaptureAndScanRequested) { _, requested in
            guard requested else { return }
            finishRegistrationFlow(to: .scan)
            router.finishCaptureAndScanRequested = false
        }
    }

    private func finishRegistrationFlow(to tab: AppRouter.Tab) {
        router.pendingTabAfterRegistrationDismiss = tab
        router.isDoorLockRegistrationPresented = false
    }
}

#Preview {
    RegistrationFlowView()
        .environment(AppRouter())
}
