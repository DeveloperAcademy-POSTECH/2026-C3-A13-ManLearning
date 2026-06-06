import SwiftUI

// MARK: - View

struct DoorLockEditView: View {
    @State private var lock: DoorLock
    @State private var showNearbyShare = false
    @Environment(\.dismiss) private var dismiss

    let onSave: (DoorLock) -> Void

    private let categories = ["도어락", "자전거", "캐리어", "기타"]

    init(lock: DoorLock, onSave: @escaping (DoorLock) -> Void) {
        _lock  = State(initialValue: lock)
        self.onSave = onSave
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                navBar
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                Text("도어락 정보 수정")
                    .textStyle(.heading)
                    .foregroundStyle(Color.textPrimary)
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

            saveButton
                .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNearbyShare) {
            NearbyShareView(lock: lock)
        }
    }

    // MARK: - Sub views

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                circleNavButton { Image(systemName: "chevron.left") }
            }
            Spacer()
            Button { showNearbyShare = true } label: {
                circleNavButton { Image(systemName: "square.and.arrow.up") }
            }
        }
    }

    // 사진 영역: 도어락 이미지 + 우측 하단 프로필 뱃지
    private var imagePlaceholder: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDefault, lineWidth: 1.5)
                Image(systemName: "camera.fill")
                    .foregroundStyle(Color.textPlaceholder)
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
                .foregroundStyle(Color.textSecondary)

            Menu {
                ForEach(categories, id: \.self) { cat in
                    Button(cat) { lock.category = cat }
                }
            } label: {
                HStack {
                    Text(lock.category)
                        .textStyle(.fieldValue)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.textPrimary)
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
                .foregroundStyle(Color.textSecondary)

            TextField("아카데미 사물함", text: $lock.name)
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
                .foregroundStyle(Color.textSecondary)

            SecureField("1234", text: $lock.password)
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
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "lock")
                .foregroundStyle(Color.infoFg)
                .font(.system(size: 18))
                .frame(width: 14)

            Text("비밀번호는 안전하게 암호화되어 저장되며, \n본인 인증 후에만 표시돼요.")
                .textStyle(.caption)
                .foregroundStyle(Color.infoFg)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.infoBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.infoBorder, lineWidth: 1)
        )
    }

    private var saveButton: some View {
        Button {
            onSave(lock)
            dismiss()
        } label: {
            Text("수정하기")
                .textStyle(.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 53)
                .background(Color.brandPrimary)
                .clipShape(Capsule())
        }
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
                .foregroundStyle(Color.textPrimary)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoorLockEditView(lock: DoorLock.samples[0], onSave: { _ in })
    }
}
