//
//  DoorLock+Display.swift
//  DoUnlock
//
//  목록 카드 등 화면 표시용 헬퍼. 모델 정의(DoorLockModel.swift)는 팀원 소유라
//  건드리지 않고, 표시 로직만 여기 별도 익스텐션으로 둔다.
//

import Foundation

extension DoorLock {
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
