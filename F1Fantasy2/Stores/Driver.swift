//
//  Driver.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation
import os
internal import Combine

/// A model representing a Formula 1 driver within a particular event context.
///
/// `Driver` holds identification info (driver_id, event_driver_id), personal details (name, car_number, team),
/// current position and points in the event, and total bids placed on this driver.
/// The `bids` property is a published array of `Bid` objects reflecting current bidding state.
/// This class is annotated with `@MainActor` to ensure UI-safe property updates, making it suitable for use in SwiftUI or other UI layers.
@MainActor
final class Driver: Identifiable, Hashable, Codable {
    let id = UUID()
    
    /// The unique identifier of the driver.
    var driver_id: Int
    
    /// The unique identifier of the driver in the context of the current event.
    var event_driver_id: Int
    
    /// The full name of the driver.
    var name: String
    
    /// The driver's car number.
    var car_number: Int
    
    /// The team the driver is currently driving for.
    var team: String
    
    /// The driver's current position in the event standings.
    var position: Int
    
    /// The total points the driver has accumulated in the event.
    var points: Int
    
    /// The total number of bids placed on this driver.
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
    
    /// The list of bids placed on this driver.
    @Published var bids: [Bid] = []
    
    /// The event identifier used as the `leagueId` in bid queries.
    var event_id: Int = -1
    
    /// Fetches the bids associated with this driver for the current league/event context.
    ///
    /// This method requests bid data from the backend using the `event_driver_id` and `event_id`
    /// (used as the `leagueId` query parameter).
    /// On success, updates the `bids` property with the retrieved bid list.
    ///
    /// - Returns: `true` if bids were successfully fetched and assigned; otherwise, `false`.
    func getBids() async -> Bool {
        do {
            let network = Network()
            let response = await network.get(endpoint: "driverBids", queryItems: [URLQueryItem(name: "eventDriverId", value: "\(event_driver_id)"), URLQueryItem(name: "leagueId", value: "\(event_id)")])
            if response.success {
                bids = try JSONDecoder().decode([Bid].self, from: response.data!)
                return true
            }
            return false
        }
        catch {
            #if DEBUG
            let logger = Logger(subsystem: "com.yourcompany.F1Fantasy2", category: "Driver")
            logger.error("Failed to fetch bids: \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    /// Equatable conformance based on unique identifier and name.
    ///
    /// Two `Driver` instances are considered equal if they share the same unique `id` and `name`.
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    /// Hashable conformance hashing the unique identifier.
    ///
    /// The hash value is derived from the driver's unique `id`.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
