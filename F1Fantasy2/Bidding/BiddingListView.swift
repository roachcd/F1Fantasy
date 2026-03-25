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
    @State private var refreshTask: Task<Void, Never>?
    @State var didNotUpdate: Bool = true
    @State var showFeeInfo: Bool = false
    
    var sortedDrivers: [Driver] {
        if let event = league.selectedEvent{
            let sorted = event.drivers.sorted { (lhs: Driver, rhs: Driver) in
                lhs.total_bids > rhs.total_bids
            }
            return sorted
        }
        return []
    }
    
    var noBids: [Driver] {
        return sortedDrivers.filter { (driver: Driver) in
            driver.total_bids == 0
        }
    }
    
    var withBids: [Driver] {
        return sortedDrivers.filter { (driver: Driver) in
            driver.total_bids > 0
        }
    }
    
    private var liveHeader: some View {
        HStack{
            Text("Currently Bidding")
            Spacer();
            if let league = userData.selectedLeague {
                if let event = league.selectedEvent {
                    if(event.status == 2){
                        if didNotUpdate {
                            ProgressView()
                        }
                        else{
                            Text("Live")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        if let league = userData.selectedLeague{
            if let event = league.selectedEvent{
                List{
                    if #unavailable(iOS 26) {
                        HomeView.AccessoryView(selectedLeague: league)
                    }
                    Section(header: liveHeader) {
                        ForEach(withBids, id: \.id) { driver in
                            NavigationLink{
                                DriverBiddingView(event: event, userData: userData, driver: driver)
                            } label: {
                                DriverLabel(driver: driver)
                            }
                        }
                    }
                    Section(header: Text("No Bids Placed")){
                        ForEach(noBids, id: \.id) { driver in
                            NavigationLink{
                                DriverBiddingView(event: event, userData: userData, driver: driver)
                            } label: {
                                DriverLabel(driver: driver)
                            }
                        }
                    }
                }
                .onAppear {
                    Task {
                        await event.load(leagueId: league.id)
                    }
                }
                .onAppear {
                    startAutoRefresh()
                }
                .onDisappear {
                    refreshTask?.cancel()
                }
                .onChange(of: event.id){
                    refreshTask?.cancel()
                    didNotUpdate = true
                    startAutoRefresh()
                    print("Event Changed")
                }
            }
        }
    }
    private func startAutoRefresh() {
        refreshTask?.cancel()

        if let league = userData.selectedLeague {
            if let event = league.selectedEvent {
                if event.status == 2{
                    refreshTask = Task {
                        while !Task.isCancelled {
                            do{
                                let success = try await withTimeout(.seconds(3)) {
                                    try await event.getDrivers(leagueId: league.id)
                                    await userData.updateThisUser()
                                    return true
                                }
                                if success{
                                    didNotUpdate = false
                                }
                                else{
                                    didNotUpdate = true
                                }
                            }catch{
                                didNotUpdate = true
                                print(error)
                            }
                            try? await Task.sleep(for: .seconds(5))
                        }
                    }
                }
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
            if(driver.total_bids != -1){
                GroupBox{
                    Text("$\(driver.total_bids)")
                }
            }
        }
    }
}

