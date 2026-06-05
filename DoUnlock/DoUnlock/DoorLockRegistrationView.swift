import SwiftUI

struct DoorLockRegistrationView: View {
    /// 등록(create) / 수정(edit) 겸용. 기본값 `.create`라 기존 `DoorLockRegistrationView()` 호출부는 그대로 동작.
    enum Mode {
        case create
        case edit(DoorLockDraft)
    }

    let mode: Mode
    /// 수정 저장 콜백. SwiftData 머지 전 인메모리 목록 갱신용 (자세한 내용은 DoorLock/INTEGRATION.md).
    var onSave: ((DoorLockDraft) -> Void)?

    @State private var category: String
    @State private var name: String
    @State private var password: String
    @Environment(\.dismiss) private var dismiss

    private let categories = ["도어락", "자전거", "캐리어", "기타"]

    init(mode: Mode = .create, onSave: ((DoorLockDraft) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _category = State(initialValue: "도어락")
            _name = State(initialValue: "")
            _password = State(initialValue: "")
        case .edit(let lock):
            _category = State(initialValue: lock.category)
            _name = State(initialValue: lock.name)
            _password = State(initialValue: lock.password)
        }
    }

    private var title: String {
        switch mode {
        case .create: return "도어락 정보 등록"
        case .edit:   return "도어락 정보 수정"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBg.ignoresSafeArea()


            VStack(alignment: .leading, spacing: 0) {
                navBar
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                Text(title)
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


            bottomButton
                .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub views

    @ViewBuilder
    private var bottomButton: some View {
        switch mode {
        case .create:
            NavigationLink(destination: RegistrationCompleteView()) {
                bottomButtonLabel("등록 완료하기")
            }
        case .edit:
            Button {
                save()
                dismiss()
            } label: {
                bottomButtonLabel("수정하기")
            }
        }
    }

    private func bottomButtonLabel(_ text: String) -> some View {
        Text(text)
            .textStyle(.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(Color.brandPrimary)
            .clipShape(Capsule())
    }
    
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
                    Button(cat) { category = cat }
                }
            } label: {
                HStack {
                    Text(category)
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
                .foregroundStyle(Color.textSecondary)
            
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
    
    // MARK: - Helpers

    /// 수정 모드 저장. 원본의 id/createAt/image는 보존하고 입력값만 갱신, updateAt은 현재로.
    private func save() {
        guard case .edit(let lock) = mode else { return }
        var updated = lock
        updated.category = category
        updated.name = name
        updated.password = password
        updated.updateAt = .now
        onSave?(updated)
    }

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

#Preview {
    NavigationStack {
        DoorLockRegistrationView()
    }
}
