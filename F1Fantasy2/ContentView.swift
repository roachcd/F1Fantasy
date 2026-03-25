//
//  ContentView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var userData = UserData()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack{
            if userData.isLaunching{
                LaunchingView()
            }
            else if userData.isLoggedIn {
                if userData.leagues.isEmpty{
                    JoinLeagueView(userData: userData)
                }
                else{
                    HomeView(userData: userData)
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .active {
                                Task{
                                    userData.isLaunching = true
                                    let success = await userData.load()
                                    if success{
                                        userData.isLaunching = false
                                    }
                                }
                            }
                        }
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
