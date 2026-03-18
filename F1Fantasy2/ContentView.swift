//
//  ContentView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

//TODO: Update money at the end of every event (cron job) and calculate the value the user has in the moment locally. Currently, users lost money on bids they didn't win

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
