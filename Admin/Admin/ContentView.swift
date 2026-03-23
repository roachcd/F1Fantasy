//
//  ContentView.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import SwiftUI

//TODO: Positions and update values

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationSplitView{
            EventsList(appData: appData)
        }detail:{
            Text("Data")
        }
    }
}

#Preview {
    ContentView().environmentObject(AppData())
}

