//
//  ContentView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var userData = UserData()
    
    var body: some View {
        NavigationStack{
            if userData.isLoggedIn {
                if userData.leagues.isEmpty{
                    JoinLeagueView(userData: userData)
                }
                else{
                    HomeView(userData: userData)
                }
            }
            else{
                LoginView(userData: userData)
            }
        }
    }
}

#Preview {
    ContentView()
}
