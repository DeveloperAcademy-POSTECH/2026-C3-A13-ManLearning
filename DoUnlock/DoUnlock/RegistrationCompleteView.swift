import SwiftUI

struct RegistrationCompleteView: View {
    @Environment(\.dismiss) private var dismiss

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
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
        }
    }

    private var textAndCard: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("도어락 등록 완료")
                    .textStyle(.heading)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("이제 집 앞에서 카메라를 비추면 비밀번호를 안전하게\n확인할수 있어요")
                    .textStyle(.subHeading)
                    .foregroundColor(.textMuted)
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
                .overlay(
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("우리집")
                    .textStyle(.cardTitle)
                    .foregroundColor(.textPrimary)
                Text("1203호 · 현관문 오른쪽 도어락")
                    .textStyle(.cardSubtitle)
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Text("등록됨")
                .textStyle(.badge)
                .foregroundColor(.successFg)
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
                dismiss()
            } label: {
                Text("등록된 목록 확인하기")
                    .textStyle(.buttonLarge)
                    .foregroundColor(.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
                    .background(Color.brandPrimaryTint)
                    .clipShape(Capsule())
            }

            Button {
                // TODO: 카메라 인식 화면으로 이동
            } label: {
                Text("바로 인식해보기")
                    .textStyle(.buttonLarge)
                    .foregroundColor(.white)
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
        RegistrationCompleteView()
    }
}
