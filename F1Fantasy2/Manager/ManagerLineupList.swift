//
//  ManagerLineupList.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/18/26.
//

import SwiftUI

struct ManagerLineupList: View{
    var manager: Manager
    var league: League
    var event: Event
    @State var loading = true
    @State var drivers: [Driver] = []
    @State var confirmed = false
    @ObservedObject var userData: UserData
    
    var body: some View{
        if loading{
            ProgressView()
                .task{
                    do{
                        var closed: Bool {
                            guard let date = TimeFormatter.shared.date(from: event.bidding_closes_at) else {
                                return false
                            }
                            return date <= Date()
                        }
                        if closed, event.status == 1 || event.status == 3 {
                            let network = Network()
                            let response = await network.get(endpoint: "eventLineup", queryItems: [URLQueryItem(name: "leagueId", value: "\(league.id)"), URLQueryItem(name: "eventId", value: "\(event.id)"), URLQueryItem(name: "userId", value: "\(manager.id)")])
                            if response.success{
                                drivers = try JSONDecoder().decode([Driver].self, from: response.data!)
                                print(drivers)
                                self.loading = false
                                self.confirmed = true
                            }
                        }
                        else{
                            let network = Network()
                            let response = await network.get(endpoint: "unofficialEventLineup", queryItems: [URLQueryItem(name: "leagueId", value: "\(league.id)"), URLQueryItem(name: "eventId", value: "\(event.id)"), URLQueryItem(name: "userId", value: "\(manager.id)")])
                            if response.success{
                                drivers = try JSONDecoder().decode([Driver].self, from: response.data!)
                                print(drivers)
                                self.loading = false
                                self.confirmed = false
                            }
                        }
                    }
                    catch{
                        print(error)
                    }
                }
        }
        else{
            Section{
                if confirmed{
                    Label("Lineups are confirmed", systemImage: "checkmark").foregroundStyle(Color(.green))
                }
                else{
                    Label("Lineups are not confirmed", systemImage: "exclamationmark.triangle").foregroundStyle(Color(.yellow))
                }
                ForEach(drivers, id: \.id) { driver in
                    NavigationLink{
                        DriverBiddingView(event: event, userData: userData, driver: driver)
                    } label: {
                        DriverLabel(driver: driver)
                    }
                }
            }
        }
    }
}
