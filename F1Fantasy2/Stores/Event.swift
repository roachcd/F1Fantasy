//
//  Event.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

/// This file defines the `Event` model, representing a racing event with timing, status, and driver list.

import SwiftUI
internal import Combine
import os

/// An `Event` represents a racing event with associated timing, status, and related drivers.
///
/// - Stores key properties like the event's dates, status, and country.
/// - Publishes a list of `drivers` associated with the event.
/// - Provides functionality to load drivers asynchronously and update its status based on bidding time.
/// - Marked as `@MainActor` for UI-safe updates.
///
/// The `Event` class conforms to `Identifiable`, `Hashable`, `Codable`, `ObservableObject`, and `Equatable`.
@MainActor
final class Event: Identifiable, Hashable, Codable, ObservableObject, Equatable {
    /// Unique identifier for the event.
    var id: Int
    
    /// Name or title of the event.
    var name: String
    
    /// The date of the event in ISO8601 string format.
    var event_date: String
    
    /// The ISO8601 timestamp string indicating when bidding closes for this event.
    var bidding_closes_at: String
    
    /// The ISO8601 timestamp string indicating when bidding starts for this event.
    var bidding_starts_at: String
    
    /// Status of the event:
    /// - 1 = Locked
    /// - 2 = Unlocked
    /// - 3 = Finished
    var status: Int
    
    /// The country associated with the event, typically an asset name or code used for flag imagery.
    var country: String
    
    /// Flags if the event is a sprint event
    var is_sprint: Int
    
    /// Flags if the event has a sprint event associated with it
    var has_sprint: Int
    
    /// Associated event id
    var sprint_event: Int
    
    var spent: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case event_date
        case bidding_closes_at
        case bidding_starts_at
        case status
        case country
        case is_sprint
        case has_sprint
        case sprint_event
    }
    
    /// The list of drivers for this event, populated after loading.
    @Published var drivers: [Driver] = []
    
    /// The list of driver the user has on their lineup
    @Published var user_lineup: [Driver] = []
    
    @Published var budget: Int = 0;
        
    
    /// Loads the drivers for this event asynchronously given a league ID.
    ///
    /// This function:
    /// - Fetches drivers from the network.
    /// - Computes whether bidding has closed based on the `bidding_closes_at` date.
    /// - Updates the `status` to locked (1) if bidding is closed and the event is not finished.
    ///
    /// - Parameter leagueId: The league identifier to filter drivers by.
    /// - Returns: `true` if drivers were successfully loaded, otherwise `false`.
    func load(leagueId: Int, token: String) async -> Bool {
        var success = true
        do {
            success = try await getDrivers(leagueId: leagueId, token: token)
            success = try await getUserDrivers(token: token, leagueId: leagueId)
            //success = try await getDriverBids(token: token, leagueId: leagueId)
            var closed: Bool {
                guard let date = TimeFormatter.shared.date(from: bidding_closes_at) else {
                    return false
                }
                return date <= Date()
            }
            if closed && status != 3 { status = 1 }
        }
        catch{
            print(error)
        }
        updateBudget()
        print(user_lineup)
        return success
    }
    
    /// Performs a network call to fetch drivers for this event within a specified league.
    ///
    /// Updates the `drivers` property with the decoded list upon success.
    ///
    /// - Parameter leagueId: The league identifier to filter drivers by.
    /// - Throws: Errors encountered during network request or decoding.
    /// - Returns: `true` if drivers were successfully fetched and decoded, otherwise `false`.
    func getDrivers(leagueId: Int, token: String) async throws -> Bool {
        let network = Network()

        let response = await network.get(
            endpoint: "eventDrivers",
            queryItems: [
                URLQueryItem(name: "eventId", value: "\(id)"),
                URLQueryItem(name: "leagueId", value: "\(leagueId)"),
                URLQueryItem(name: "token", value: token)
            ]
        )

        guard response.success, let data = response.data else {
            return false
        }

        let loadedDrivers = try JSONDecoder().decode([Driver].self, from: data)

        await MainActor.run {
            self.drivers = loadedDrivers
        }

        return true
    }
    
    func getDriverBids(token: String, leagueId: Int) async throws -> Bool {
        var updatedDrivers = drivers
        var allSuccess = true
        await withTaskGroup(of: (Int, Bool).self) { group in
            for (index, driver) in updatedDrivers.enumerated() {
                group.addTask {
                    let success = try? await driver.getDriverBid(token: token, leagueId: leagueId)
                    return (index, success == true)
                }
            }
            for await (index, success) in group {
                if !success { allSuccess = false }
                // The driver's bid property is already updated inside getDriverBid
                // No need to do more unless you want to deep-copy, but current approach is fine
            }
        }
        // Assign all at once so the UI does not see interim updates
        drivers = updatedDrivers
        return allSuccess
    }
    
    func getUserDrivers(token: String, leagueId: Int) async throws -> Bool {
        let network = Network()
        let response = await network.get(endpoint: "eventLineup", queryItems: [URLQueryItem(name: "eventId", value: "\(id)"), URLQueryItem(name: "leagueId", value: "\(leagueId)")], token: token)
        if response.success {
            user_lineup = try JSONDecoder().decode([Driver].self, from: response.data!)
            return true
        }
        return false
    }
    
    func updateBudget(){
        print("Update Budget")
        spent = 0;
        if is_sprint == 0{
            for driver in user_lineup {
                spent = spent + driver.cost
            }
        }
        else{
            for driver in drivers{
                spent = spent + (driver.bid?.amount ?? 0)
            }
        }
        budget = 100 - spent;
    }
    
    func removeDriver(driver: Driver, leagueId: Int, token: String) async throws -> Bool{
        user_lineup.removeAll(where: { $0.id == driver.id })
        updateBudget()
        
        let network = Network()
        let response = await network.post(endpoint: "removeDriver", body: ["token": token, "driver_id": driver.driver_id, "league_id": leagueId, "event_id": id, "event_driver_id" : driver.event_driver_id])
        if response.success{
            return true
        }
        else{
            return false
        }
    }
    
    func addDriver(driver: Driver, leagueId: Int, token: String) async throws -> Bool{
        user_lineup.append(driver)
        updateBudget()
        
        let network = Network()
        let response = await network.post(endpoint: "addDriver", body: ["token": token, "driver_id": driver.driver_id, "league_id": leagueId, "event_id": id, "event_driver_id" : driver.event_driver_id])
        if response.success{
            return true
        }
        else{
            return false
        }
    }
    // MARK: - Equatable Conformance
    
    /// Equatable conformance comparing events by their `id` and `name`.
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // MARK: - Hashable Conformance
    
    /// Hashable conformance using the unique `id` of the event.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
