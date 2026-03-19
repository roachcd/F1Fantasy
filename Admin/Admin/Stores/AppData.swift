//
//  AppData.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import Foundation
internal import Combine

@MainActor
final class AppData: ObservableObject {
    @Published var events: [Event] = []
    @Published var allDrivers: [Driver] = []
    
    func getEvents() async -> Bool{
        let network = Network()
        let response = await network.get(endpoint: "events", queryItems: [URLQueryItem(name: "seasonId", value: "\(1)")])
        if response.success{
            do{
                events = try JSONDecoder().decode([Event].self, from: response.data!)
                print(events)
                for event in events{
                    _ = await event.load()
                }
                return true
            }catch{
                print(error)
                return false
            }
        }
        return false
    }
    
    func getAllDrivers() async -> Bool{
        let network = Network()
        let response = await network.get(endpoint: "drivers")
        if response.success{
            do{
                allDrivers = try JSONDecoder().decode([Driver].self, from: response.data!)
                print(allDrivers)
                return true
            }catch{
                print(error)
                return false
            }
        }
        return false
    }
}
