// FaceIDView.swift
// DoUnlock
//
// LocalAuthentication 프레임워크를 사용해 Face ID 인증을 테스트하는 뷰입니다.
// 참고: https://developer.apple.com/documentation/localauthentication

import SwiftUI
import LocalAuthentication // LAContext, LAPolicy, LAError 등 생체 인증 관련 타입을 제공하는 프레임워크

struct FaceIDView: View {

    // MARK: - State

    // 인증 성공 여부. true가 되면 body가 자동으로 다시 그려집니다.
    @State private var isAuthenticated: Bool = false

    // 인증 실패 시 사용자에게 보여줄 에러 메시지. 빈 문자열이면 UI에 표시하지 않습니다.
    @State private var errorMessage: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {

            // isAuthenticated 값에 따라 자물쇠 아이콘과 색상이 바뀝니다.
            // SF Symbols 이름을 삼항연산자로 전환해 인증 상태를 시각적으로 표현합니다.
            Image(systemName: isAuthenticated ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(isAuthenticated ? .green : .gray)

            // 아이콘과 함께 인증 상태를 텍스트로도 안내합니다.
            Text(isAuthenticated ? "인증 성공" : "잠금 상태")

            // 탭하면 authenticate()를 실행해 Face ID 다이얼로그를 띄웁니다.
            Button("Face ID 인증") {
                authenticate()
            }
            .buttonStyle(.borderedProminent)

            // 에러 메시지가 존재할 때만 빨간 텍스트로 보여줍니다.
            // 인증 성공 후에도 errorMessage를 초기화하지 않으면 둘 다 표시될 수 있으니 주의하세요.
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .navigationTitle("Face ID 테스트")
    }

    // MARK: - Authentication

    private func authenticate() {

        // 하나의 인증 요청마다 새 LAContext를 만드는 것이 Apple 권장 방식입니다.
        // context는 인증 세션의 상태(정책, 에러, 재사용 여부 등)를 관리합니다.
        let context = LAContext()

        // canEvaluatePolicy는 Swift throws 가 아닌 NSError inout 패턴을 사용합니다.
        // 옵셔널로 선언하고 &error 로 넘기면, 실패 시 함수 내부에서 값을 채워줍니다.
        var error: NSError?

        // 실제 인증을 시도하기 전에 이 기기에서 인증이 가능한지 먼저 확인합니다.
        // Face ID 미등록, 기기 미지원 등의 경우 false를 반환하고 error에 사유를 담습니다.
        //
        // [정책 비교]
        // .deviceOwnerAuthenticationWithBiometrics
        //   → Face ID / Touch ID 생체 인증만 허용합니다.
        //     실패가 반복되면 잠기고 에러를 반환합니다. 암호 입력으로 넘어가지 않습니다.
        //
        // .deviceOwnerAuthentication
        //   → 생체 인증을 먼저 시도하고, 실패 시 자동으로 기기 암호 입력으로 fallback 합니다.
        //     생체 인증이 아예 없는 기기에서도 암호만으로 인증이 가능합니다.
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {

            // 사용자에게 Face ID 다이얼로그를 띄웁니다.
            // localizedReason은 다이얼로그 안에 표시되는 인증 목적 안내 문구입니다.
            // reply 클로저는 인증이 끝난 뒤 백그라운드 스레드에서 호출됩니다.
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "잠금을 해제합니다."
            ) { success, authError in

                // @State 프로퍼티 변경은 반드시 메인 스레드에서 해야 합니다.
                // 백그라운드에서 직접 바꾸면 UI 업데이트가 보장되지 않거나 크래시가 날 수 있습니다.
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        // authError는 LAError 타입입니다. 사용자가 취소한 경우(.userCancel),
                        // 인식 실패(.authenticationFailed) 등 다양한 케이스가 있습니다.
                        self.errorMessage = authError?.localizedDescription ?? "인증 실패"
                    }
                }
            }

        } else {
            // canEvaluatePolicy가 false인 경우 — Face ID 자체를 쓸 수 없는 상황입니다.
            // 이 경우도 UI 업데이트이므로 메인 스레드로 전환합니다.
            DispatchQueue.main.async {
                self.errorMessage = error?.localizedDescription ?? "Face ID를 사용할 수 없습니다."
            }
        }
    }
}

#Preview {
    NavigationStack {
        FaceIDView()
    }
}
