//
//  MyLineupView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 4/9/26.
//

import SwiftUI

struct MyLineupView: View {
    @State var drivers: [Driver] = []
    @State var loading = true;
    @State var addingDriver = false;
    
    @ObservedObject var userData: UserData
    @ObservedObject var league: League
    @ObservedObject var event: Event

    
    var body: some View {
        List{
            Section{
                if #unavailable(iOS 26) {
                    HomeView.AccessoryView(selectedLeague: league, event: event)
                }
            }
            Section{
                ForEach(event.user_lineup, id: \.id) { driver in
                    NavigationLink{
                        DriverView(driver: driver, event: event, userData: userData)
                    } label: {
                        DriverLabel(driver: driver)
                    }
                }
                if event.status == 2{
                    Button{
                        addingDriver = true
                    }label: {
                        Text("Add Driver")
                    }
                }
            }
        }
        .task {
            do{
                print("getting user lineup")
                let success = try await event.getUserDrivers(token: userData.token, leagueId: league.id)
                if(!success){
                    print("Failed to get user lineup")
                }
            }
            catch{
                print(error)
            }
        }
        .sheet(isPresented: $addingDriver) {
            NavigationView {
                DriverListView(event: event, userData: userData)
            }
        }
    }
}
