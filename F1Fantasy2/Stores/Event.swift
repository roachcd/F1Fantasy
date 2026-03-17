//
//  Event.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

import SwiftUI
internal import Combine

@MainActor
final class Event: Identifiable, Hashable, Codable, ObservableObject{
    var id: Int
    var name: String
    var event_date: String
    var status: Int
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case event_date
        case status
    }
    
    @Published var drivers: [Driver] = []
    
    func load() async -> Bool{
        var success = true
        do{
            success = try await getDrivers()
        }
        catch{
            print(error)
        }
        return success
    }
    
    func getDrivers() async throws -> Bool{
        let network = Network()
        print(id)
        let response = await network.get(endpoint: "eventDrivers", queryItems: [URLQueryItem(name: "eventId", value: "\(id)")])
        if response.success{
            let decoded = try JSONDecoder().decode([Driver].self, from: response.data!)
            await MainActor.run {
                self.drivers = decoded
            }
            print(drivers)
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
