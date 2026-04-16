//
//  ManagerLineupList.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/18/26.
//

import SwiftUI

/// A view that displays the lineup of drivers for a given manager in a league event.
///
/// - Parameters:
///   - `manager`: The manager whose lineup is being displayed.
///   - `league`: The league context for the event.
///   - `event`: The event for which the lineup is shown.
///   - `userData`: The observed user data object.
struct ManagerLineupList: View{
    var manager: Manager
    var league: League
    var event: Event
    @State var loading = true
    @State var drivers: [Driver] = []
    @State var confirmed = false
    @ObservedObject var userData: UserData
    
    var body: some View{
        Section{
            if loading{
                ProgressView()
                    .task{
                        do{
                            let network = Network()
                            let response = await network.get(endpoint: "eventLineup", queryItems: [URLQueryItem(name: "leagueId", value: "\(league.id)"), URLQueryItem(name: "eventId", value: "\(event.id)"), URLQueryItem(name: "userId", value: "\(manager.id)")])
                            if response.success{
                                drivers = try JSONDecoder().decode([Driver].self, from: response.data!)
                                self.loading = false
                            }
                        }
                        catch{
                            print(error)
                        }
                    }
            }
            else{
                ForEach(drivers, id: \.id) { driver in
                    NavigationLink{
                        DriverView(driver: driver, event: event, userData: userData)
                    } label: {
                        DriverLabel(driver: driver)
                    }
                }
                if drivers.isEmpty{
                    Text("No drivers in lineup")
                }
            }
        }
    }
}
