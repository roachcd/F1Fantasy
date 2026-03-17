//
//  BiddingListView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct BiddingListView: View {
    @ObservedObject var league: League
    @ObservedObject var event: Event
    @ObservedObject var userData: UserData

    var sortedDrivers: [Driver] {
        event.drivers.sorted { $0.total_bids > $1.total_bids }
    }
    
    var body: some View {
        List{
            ForEach(sortedDrivers, id: \.id) { driver in
                NavigationLink{
                    DriverBiddingView(event: event, userData: userData, driver: driver)
                } label: {
                    DriverLabel(driver: driver)
                }
            }
        }
        .onAppear {
            Task {
                await event.load()
            }
        }
    }
}


struct DriverLabel: View{
    var driver: Driver
    
    var body: some View{
        HStack{
            Image("\(driver.name)")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(.secondary, lineWidth: 2)
                )
            Text("\(driver.name)")
            Spacer()
            GroupBox{
                Text("$\(driver.total_bids)")
            }
        }
    }
}
