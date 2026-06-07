//
//  SwiftData.swift
//  DoUnlock
//
//  Created by 정필규 on 6/5/26.
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
