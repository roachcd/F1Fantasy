//
//  LaunchingView.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 3/12/26.
//

import SwiftUI

/// A view that is presented while the app is launching or reloading essential data

struct LaunchingView: View{
    @State private var showContent = false
    
    var body: some View {
        VStack{
            Image("Icon").resizable().frame(width: 100, height: 100).padding()
            if showContent{
                ProgressView()
                Text("server starting, in development this can take over a minute").padding().frame(alignment: .center)
            }
        }
        .task() {
            try? await Task.sleep(for: .seconds(4))
            showContent = true
        }
    }
}
