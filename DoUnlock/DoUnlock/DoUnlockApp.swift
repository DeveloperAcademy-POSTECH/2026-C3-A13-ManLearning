//
//  DoUnlockApp.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI
import SwiftData

@main
struct DoUnlockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DoorLock.self)
    }
}
