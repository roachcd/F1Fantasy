//
//  Driver.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation
internal import Combine

@MainActor
final class Driver: Identifiable, Hashable, Codable{
    let id = UUID()
    var driver_id: Int
    var event_driver_id: Int
    var name: String
    var car_number: Int
    var team: String
    var position: Int
    var points: Int
    var total_bids: Int
    enum CodingKeys: String, CodingKey {
        case id
        case driver_id
        case event_driver_id
        case name
        case car_number
        case team
        case position
        case total_bids
        case points
    }
    
    @Published var bids: [Bid] = []
    var event_id: Int = -1
    
    func getBids() async -> Bool{
        do{
            let network = Network()
            let response = await network.get(endpoint: "driverBids", queryItems: [URLQueryItem(name: "eventDriverId", value: "\(event_driver_id)"), URLQueryItem(name: "leagueId", value: "\(event_id)")])
            if response.success{
                bids = try JSONDecoder().decode([Bid].self, from: response.data!)
                return true
            }
            return false
        }
        catch{
            print(error)
            return false
        }
    }
    
    // Conformance to Equatable
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
