//
//  League.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI
internal import Combine

@MainActor
final class League : Identifiable, Hashable, Codable, ObservableObject {
    var id: Int
    var name: String
    var ownerId: Int
    var season_id: Int
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerId
        case season_id
    }
    
    @Published var events: [Event] = []
    @Published var selectedEvent: Event?
    @Published var managers: [Manager] = []
    
    struct ThisUser: Decodable {
        var user_id: Int
        var username: String
        var money: Int
    }
    
    @Published var thisUser: ThisUser = ThisUser(user_id: -1, username: "Error", money: 0)
    
    func load(token: String) async -> Bool{
        var success = false
        
        do{
            success = try await self.getThisUser(token: token)
            success = try await self.getManagers()
            success = try await self.getEvents()
        }
        catch{
            print(error)
            return false
        }

        if success{
            return true
        }
        return false
    }
    
    func getThisUser(token: String) async throws -> Bool{
        let network = Network()
        let response = await network.get(endpoint: "thisLeagueUser", queryItems: [URLQueryItem(name: "leagueId", value: "\(id)")], token: token)
        if response.success{
            let data = response.data
            let thisUsers: [ThisUser] = try JSONDecoder().decode([ThisUser].self, from: data!)
            self.thisUser = thisUsers.first!
            return true
        }
        return false
    }
    
    func getManagers() async throws -> Bool {
        let network = Network()
        let response = await network.get(endpoint: "leagueManagers", queryItems: [URLQueryItem(name: "leagueId", value: "\(id)")])
        if response.success{
            let managers = try JSONDecoder().decode([Manager].self, from: response.data!)
            self.managers = managers
            return true
        }
        return false
    }
    
    func getEvents() async throws -> Bool{
        let network = Network()
        let response = await network.get(endpoint: "events", queryItems: [URLQueryItem(name: "seasonId", value: "\(season_id)")])
        if response.success{
            let data = response.data
            events = try JSONDecoder().decode([Event].self, from: data!)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            self.selectedEvent = self.events
                .compactMap { event -> (event: Event, date: Date)? in
                    guard let date = formatter.date(from: event.event_date) else { return nil }
                    return (event, date)
                }
                .filter { $0.date > Date() }
                .min { $0.date < $1.date }?
                .event
            
            print(self.selectedEvent ?? "No Event")
            if await self.selectedEvent!.load(leagueId: id){
                return true
            }
            return false
        }
        return false
    }
    
    
    // Conformance to Equatable
    static func == (lhs: League, rhs: League) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

