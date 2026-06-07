//
//  DoorLockModel.swift
//  DoUnlock
//
//  Created by 정필규 on 6/5/26.
//
//  ⚠️ 모델 정의는 origin/siri_remi의 모델과 동일한 내용이며,
//  파일명만 SwiftData.swift → DoorLockModel.swift 로 변경했습니다.
//  (파일명이 SwiftData면 import SwiftData 가 무시되어 @Model 이 인식되지 않는 Swift 버그 회피)
//  siri_remi 머지 시 한쪽으로 수렴시키면 됩니다(클래스 정의는 1:1 동일).
//

import Foundation
import SwiftData


// 저장 객체
@Model
class DoorLock{
    var id: UUID
    var category: String
    var name: String
    var password: String
    var image: Data
    var createAt: Date
    var updateAt: Date


    init(category: String, name: String, password: String, image:Data){
        self.id = UUID()
        self.category = category
        self.name = name
        self.password = password
        self.image = image
        self.createAt = Date()
        self.updateAt = Date()



    }
}
