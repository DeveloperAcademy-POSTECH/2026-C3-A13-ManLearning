import SwiftUI

struct DoorLockRegistrationView: View {
    @State private var category = "도어락"
    @State private var name = ""
    @State private var password = ""
    @Environment(\.dismiss) private var dismiss

    private let categories = ["도어락", "사물함", "현관문", "기타"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    navBar
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    Text("도어락 정보 등록")
                        .textStyle(.heading)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 16) {
                        imagePlaceholder
                        categoryField
                        nameField
                        passwordField
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 36)

                    infoNotice
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                        .padding(.bottom, 100)
                }
            }

            NavigationLink(destination: RegistrationCompleteView()) {
                Text("등록 완료하기")
                    .textStyle(.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub views

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                circleNavButton { Image(systemName: "chevron.left") }
            }
            Spacer()
            Button { } label: {
                circleNavButton { Image(systemName: "square.and.arrow.up") }
            }
        }
    }

    private var imagePlaceholder: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDefault, lineWidth: 1.5)
                Image(systemName: "camera.fill")
                    .foregroundColor(.textPlaceholder)
                    .font(.system(size: 28))
            }
            .frame(width: 174, height: 202)
            Spacer()
        }
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("카테고리")
                .textStyle(.fieldLabel)
                .foregroundColor(.textSecondary)

            Menu {
                ForEach(categories, id: \.self) { cat in
                    Button(cat) { category = cat }
                }
            } label: {
                HStack {
                    Text(category)
                        .textStyle(.fieldValue)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderDefault, lineWidth: 1.5)
                )
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("이름")
                .textStyle(.fieldLabel)
                .foregroundColor(.textSecondary)

            TextField("아카데미 사물함", text: $name)
                .textStyle(.fieldValue)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderDefault, lineWidth: 1.5)
                )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("비밀번호")
                .textStyle(.fieldLabel)
                .foregroundColor(.textSecondary)

            SecureField("1234", text: $password)
                .textStyle(.fieldValue)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderDefault, lineWidth: 1.5)
                )
        }
    }

    private var infoNotice: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "lock")
                .foregroundColor(.infoFg)
                .font(.system(size: 14))
                .frame(width: 14)

            Text("비밀번호는 안전하게 암호화되어 저장되며, 본인 인증 후에만 표시돼요.")
                .textStyle(.caption)
                .foregroundColor(.infoFg)
                .lineSpacing(5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.infoBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.infoBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    @ViewBuilder
    private func circleNavButton<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Circle()
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.08), radius: 1.5, x: 0, y: 1)
                .overlay(Circle().stroke(Color.borderDefault, lineWidth: 1))
            content()
                .foregroundColor(.textPrimary)
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    NavigationStack {
        DoorLockRegistrationView()
    }
}
