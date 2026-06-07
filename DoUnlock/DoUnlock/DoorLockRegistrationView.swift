import SwiftUI
import SwiftData

struct DoorLockRegistrationView: View {
    /// 등록(create) / 수정(edit) 겸용. 기본값 `.create`라 기존 `DoorLockRegistrationView()` 호출부는 그대로 동작.
    enum Mode {
        case create
        case edit(DoorLock)
    }

    let mode: Mode
    /// 촬영 플로우(다른 팀원 담당)에서 캡처한 크롭 이미지. create 시 저장/표시.
    /// 촬영 연결 전 목록의 create 진입은 placeholder(Data())를 전달.
    let cropimageData: Data
    /// 원본 전체 이미지. 현재 미사용 — 추후 원본 저장용 seam.
    let fullimageData: Data

    @State private var category: String
    @State private var name: String
    @State private var password: String
    @State private var showShareSheet = false
    @State private var didComplete = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let categories = ["도어락", "자전거", "캐리어", "기타"]

    init(mode: Mode = .create, cropimageData: Data = Data(), fullimageData: Data = Data()) {
        self.mode = mode
        self.cropimageData = cropimageData
        self.fullimageData = fullimageData
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
        .sheet(isPresented: $showShareSheet) {
            DeviceShareSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // create 모드: 저장(insert) 후 완료 화면으로 이동.
        .navigationDestination(isPresented: $didComplete) {
            RegistrationCompleteView(name: name, category: category, imageData: cropimageData)
        }
    }

    // MARK: - Sub views

    @ViewBuilder
    private var bottomButton: some View {
        switch mode {
        case .create:
            Button {
                create()
            } label: {
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
            // 공유는 저장된 도어락(수정 모드)에서만. create 모드(미저장)에선 숨김.
            if case .edit = mode {
                Button { showShareSheet = true } label: {
                    circleNavButton { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
    }
    
    /// 표시할 사진. create는 넘겨받은 촬영 이미지, edit는 저장된 도어락 이미지.
    private var displayImageData: Data {
        switch mode {
        case .create:          return cropimageData
        case .edit(let lock):  return lock.image
        }
    }

    private var imagePlaceholder: some View {
        HStack {
            Spacer()
            ZStack {
                if let uiImage = UIImage(data: displayImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.surface
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.textPlaceholder)
                        .font(.system(size: 28))
                }
            }
            .frame(width: 174, height: 202)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDefault, lineWidth: 1.5)
            )
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
                .foregroundStyle(Color.black)
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
                .foregroundStyle(Color.black)
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

    /// 등록 모드: 새 DoorLock을 저장소에 추가하고 완료 화면으로 이동.
    /// 이미지는 촬영 플로우에서 넘어온 크롭본(cropimageData). 촬영 미연결 진입은 빈 Data() 플레이스홀더.
    private func create() {
        let lock = DoorLock(category: category, name: name, password: password, image: cropimageData)
        modelContext.insert(lock)
        didComplete = true
    }

    /// 수정 모드 저장. DoorLock은 참조 타입이라 객체를 직접 수정하면 SwiftData가 autosave.
    /// id/createAt/image는 보존하고 입력값만 갱신, updateAt은 현재로(목록 날짜 라벨 기준).
    private func save() {
        guard case .edit(let lock) = mode else { return }
        lock.category = category
        lock.name = name
        lock.password = password
        lock.updateAt = .now
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
        DoorLockRegistrationView(
            cropimageData:UIImage(named: "photo")!.jpegData(compressionQuality: 0.8)!,

            fullimageData: UIImage(named: "photo")!.jpegData(compressionQuality: 0.8)!
            
        )
    }
}
