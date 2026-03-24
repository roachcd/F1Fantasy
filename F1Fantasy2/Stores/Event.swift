//
//  Event.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

import SwiftUI
internal import Combine

@MainActor
final class Event: Identifiable, Hashable, Codable, ObservableObject, Equatable{
    var id: Int
    var name: String
    var event_date: String
    var bidding_closes_at: String
    var bidding_starts_at: String
    var status: Int
    var country: String
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case event_date
        case bidding_closes_at
        case bidding_starts_at
        case status
        case country
    }
    
    @Published var drivers: [Driver] = []
    @StateObject var userData = UserData()
    
    func load(leagueId: Int) async -> Bool{
        var success = true
        do{
            success = try await getDrivers(leagueId: leagueId)
            var closed: Bool {
                guard let date = TimeFormatter.shared.date(from: bidding_closes_at) else {
                    return false
                }
                return date <= Date()
            }
            if closed && status != 3 {status = 1}
        }
        catch{
            print(error)
        }
        return success
    }
    
    func getDrivers(leagueId: Int) async throws -> Bool{
        let network = Network()
        print(id)
        let response = await network.get(endpoint: "eventDrivers", queryItems: [URLQueryItem(name: "eventId", value: "\(id)"), URLQueryItem(name: "leagueId", value: "\(leagueId)")])
        if response.success{
            drivers = try JSONDecoder().decode([Driver].self, from: response.data!)
            return true
        }
        return false
    }
    
    // Conformance to Equatable
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
