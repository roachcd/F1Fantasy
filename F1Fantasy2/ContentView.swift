//
//  ContentView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        NavigationStack{
            if userData.isLoggedIn {
                HomeView(userData: userData)
            }
            else{
                LoginView(userData: userData)
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(UserData())
}
