//
//  ContentView.swift
//  DoUnlock
//
//  Created by Karl on 5/29/26.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        ZStack{
            CameraPreviewView(
                isActive: true, frameHandler:{ _ in}
            ).ignoresSafeArea()

        }
        
        
        
    }
}
        
    


#Preview {
    ContentView()
}
