import SwiftUI
import SwiftData

struct DoorLockRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var category = "도어락"
    @State private var name = ""
    @State private var password = ""
    @State private var isRegistrationComplete = false
    let imageData: Data
    
    @Environment(\.dismiss) private var dismiss
    
    private let categories = ["도어락", "자전거", "캐리어", "기타"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBg.ignoresSafeArea()
            
            
            VStack(alignment: .leading, spacing: 0) {
                navBar
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                
                Text("도어락 정보 등록")
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
            
            Button {
                saveDoorLock()
                isRegistrationComplete = true
            } label: {
                Text("등록 완료하기")
                    .textStyle(.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 53)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
            .navigationDestination(isPresented: $isRegistrationComplete) {
                RegistrationCompleteView(name: name, category: category, imageData: imageData)
            }
            .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Sub views
    
    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                circleNavButton { Image(systemName: "chevron.left") }
            }

        }
    }
    
    private var imagePlaceholder: some View {
        HStack {
            Spacer()
            ZStack {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.surface
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.textPlaceholder)
                        .font(.system(size: 28))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderDefault, lineWidth: 1.5)
            )
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
    
    private func saveDoorLock()
    {
        let newDoorLock = DoorLock(
            category :category,
            name: name,
            password: password,
            image: imageData
        )
        modelContext.insert(newDoorLock)
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

#Preview {
    NavigationStack {
        DoorLockRegistrationView(
            imageData: UIImage(named: "photo")!.jpegData(compressionQuality: 0.8)!
        )
    }
}
