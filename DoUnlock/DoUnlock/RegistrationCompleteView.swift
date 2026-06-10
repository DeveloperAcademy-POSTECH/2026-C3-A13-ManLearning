import SwiftUI

struct RegistrationCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let name: String
    let category: String
    let imageData : Data

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 40) {
                    successIcon
                    textAndCard
                }
                .padding(.horizontal, 15)

                Spacer()
                Spacer()

                actionButtons
                    .padding(.horizontal, 15)
                    .padding(.bottom, 34)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub views

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimaryTint)
                .frame(width: 120, height: 120)
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 70, height: 70)
            Image(systemName: "checkmark")
                .foregroundStyle(.white)
                .font(.system(size: 24, weight: .bold))
        }
    }

    private var textAndCard: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("도어락 등록 완료")
                    .textStyle(.completionTitle)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("이제 집 앞에서 카메라를 비추면 비밀번호를 안전하게\n확인할수 있어요")
                    .textStyle(.subHeading)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }

            registeredLockCard
        }
    }

    private var registeredLockCard: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [.lockIconStart, .lockIconEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 55)
                .overlay {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 55)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 15))
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text(category)
                    .textStyle(.cardSubtitle)
                    .foregroundStyle(Color.textMuted)

            }

            Spacer()

            Text("등록됨")
                .textStyle(.badge)
                .foregroundStyle(Color.successFg)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.successBg)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                // 등록 플로우를 닫고 목록(password) 탭으로 전환하도록 상위 flow에 신호를 보낸다.
                router.finishCaptureFlowRequested = true
            } label: {
                Text("등록된 목록 확인하기")
                    .textStyle(.buttonLarge)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
                    .background(Color.brandPrimaryTint)
                    .clipShape(Capsule())
            }

            Button {
                router.finishCaptureAndScanRequested = true
            } label: {
                Text("바로 인식해보기")
                    .textStyle(.buttonLarge)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegistrationCompleteView(name: "우리집", category: "도어락", imageData: UIImage(named: "photo")!.jpegData(compressionQuality: 0.8)!)
    }
    .environment(AppRouter())
}
