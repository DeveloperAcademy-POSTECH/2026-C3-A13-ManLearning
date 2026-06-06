import Foundation
import Combine

// MARK: - ViewModel

final class DoorLockListViewModel: ObservableObject {
    @Published var locks: [DoorLock] = DoorLock.samples

    // 목록에 도어락 추가
    func add(_ lock: DoorLock) {
        locks.append(lock)
    }

    // 기존 도어락 수정 (id 기준)
    func update(_ lock: DoorLock) {
        guard let index = locks.firstIndex(where: { $0.id == lock.id }) else { return }
        locks[index] = lock
    }

    // 스와이프 삭제
    func delete(at offsets: IndexSet) {
        offsets.sorted(by: >).forEach { locks.remove(at: $0) }
    }
}
