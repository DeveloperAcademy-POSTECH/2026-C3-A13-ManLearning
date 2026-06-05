//
//  DoorLockDraft.swift
//  DoUnlock
//
//  ⚠️ 임시(stand-in) 모델입니다.
//  레미가 작성 중인 SwiftData `@Model class DoorLock`을 머지하면:
//    1. 이 파일을 삭제하고
//    2. `DoorLockDraft` → `DoorLock` 으로 교체
//    3. 뷰의 `@State private var locks = DoorLockDraft.sampleData` → `@Query private var locks: [DoorLock]`
//  로 갈아끼우면 됩니다. 그 교체가 1:1이 되도록 필드 이름/타입을 실제 모델과 동일하게 맞췄습니다.
//
//  실제 모델(참고):
//    @Model class DoorLock {
//        var id: UUID; var category: String; var name: String; var password: String
//        var image: Data; var createAt: Date; var updateAt: Date
//    }
//

import Foundation

struct DoorLockDraft: Identifiable {
    let id: UUID
    var category: String   // 도어락 / 자전거 / 캐리어 / 기타
    var name: String       // 예: 우리집
    var password: String   // 임시 평문 (추후 암호화/Keychain은 저장 계층에서)
    var image: Data        // 도어락 사진 (더미는 빈 Data())
    var createAt: Date
    var updateAt: Date     // 목록 카드의 날짜 라벨 기준

    init(
        id: UUID = UUID(),
        category: String = "도어락",
        name: String,
        password: String = "",
        image: Data = Data(),
        createAt: Date = .now,
        updateAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.password = password
        self.image = image
        self.createAt = createAt
        self.updateAt = updateAt
    }
}

extension DoorLockDraft {
    /// `updateAt`을 기준으로 한 상대 날짜 라벨. 예: "오늘", "어제", "3일 전".
    var lastUsedLabel: String {
        let calendar = Calendar.current
        let startOfUpdate = calendar.startOfDay(for: updateAt)
        let startOfToday = calendar.startOfDay(for: .now)
        let days = calendar.dateComponents([.day], from: startOfUpdate, to: startOfToday).day ?? 0

        switch days {
        case ..<0: return "오늘"   // 미래 값 방어
        case 0:    return "오늘"
        case 1:    return "어제"
        default:   return "\(days)일 전"
        }
    }
}

extension DoorLockDraft {
    /// 화면 확인용 더미데이터. 실제 저장 계층 연결 시 제거됩니다.
    static let sampleData: [DoorLockDraft] = [
        DoorLockDraft(category: "도어락", name: "우리집", password: "1234", updateAt: .now),
        DoorLockDraft(
            category: "자전거",
            name: "본가",
            password: "5678",
            updateAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
        ),
        DoorLockDraft(
            category: "캐리어",
            name: "사무실",
            password: "0000",
            updateAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        ),
    ]
}
