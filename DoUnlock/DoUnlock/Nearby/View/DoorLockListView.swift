import SwiftUI

// MARK: - View

struct DoorLockListView: View {
    @StateObject private var viewModel = DoorLockListViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.screenBg.ignoresSafeArea()

                // 스크롤 영역: 타이틀 + 카드 목록
                VStack(spacing: 0) {
                    pageTitle
                        .padding(.top, 25)

                    lockList
                        .padding(.top, 35)
                        .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.bottom, 160) // 버튼 + 탭바 영역 확보

                // 하단 고정: 버튼 → 12pt → 탭바
                VStack(spacing: 12) {
                    addButton
                        .padding(.horizontal, 16)

                    tabBar
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub views

    // 가운데 정렬 타이틀
    private var pageTitle: some View {
        Text("등록된 도어락 목록")
            .textStyle(.brandName)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var lockList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.locks.enumerated()), id: \.element.id) { index, lock in
                NavigationLink(destination: DoorLockEditView(lock: lock, onSave: viewModel.update)) {
                    LockRowView(lock: lock, index: index)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // 점선 테두리 버튼 — Capsule 모양
    private var addButton: some View {
        NavigationLink(destination: DoorLockRegistrationView()) {
            HStack(spacing: 9) {
                Image(systemName: "plus")
                Text("새 도어락 등록하기")
                    .textStyle(.bodyText)
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.top, 13)
            .padding(.bottom, 17)
            .overlay(
                Capsule()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(Color.brandPrimary.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab bar

    // 전체가 pill 모양으로 플로팅
    private var tabBar: some View {
        HStack(spacing: 4) {
            tabScanItem
            tabPasswordItem
        }
        .padding(4)
        .background(Color.surface)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 91)
        .padding(.bottom, 21)
    }

    // scan 탭: 배경 없음
    private var tabScanItem: some View {
        VStack(spacing: 4) {
            Image(systemName: "camera")
                .font(.system(size: 22))
            Text("scan")
                .textStyle(.caption)
        }
        .foregroundStyle(Color.textMuted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // password 탭: 내부 캡슐 배경 (회색)
    private var tabPasswordItem: some View {
        VStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
            Text("password")
                .textStyle(.caption)
        }
        .foregroundStyle(Color.brandPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.screenBg)
        .clipShape(Capsule())
    }
}

// MARK: - Lock Row

struct LockRowView: View {
    let lock: DoorLock
    let index: Int

    // 더미 데이터용: 카드마다 다른 배경색 (실제 앱에서는 사진으로 대체)
    private static let photoColors: [Color] = [
        Color(red: 0.07, green: 0.07, blue: 0.16),  // 딥 네이비
        Color(red: 0.05, green: 0.20, blue: 0.18),  // 딥 틸
        Color(red: 0.18, green: 0.08, blue: 0.24),  // 딥 퍼플
    ]

    var body: some View {
        HStack(spacing: 12) {
            photoPlaceholder

            VStack(alignment: .leading, spacing: 3) {
                Text(lock.name)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                Text(lock.roomNumber)
                    .textStyle(.caption)
                    .foregroundStyle(Color.textMuted)
                Text(lock.location)
                    .textStyle(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textMuted)
                    .font(.system(size: 12, weight: .medium))
                Text(dateLabel(for: lock.registeredDate))
                    .textStyle(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 12) // 카드 간 간격
    }

    // 도어락 사진 영역: portrait 직사각형 (4:5 비율)
    // 실제 앱에서는 등록 시 찍은 사진 표시
    private var photoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LockRowView.photoColors[index % LockRowView.photoColors.count])
            Image(systemName: "lock.fill")
                .foregroundStyle(.white.opacity(0.8))
                .font(.system(size: 16, weight: .medium))
        }
        .frame(width: 50, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) // portrait 직사각형
    }

    private func dateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "오늘" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    DoorLockListView()
}
