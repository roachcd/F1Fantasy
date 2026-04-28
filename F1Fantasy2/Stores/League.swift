//
//  League.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//


import SwiftUI
internal import Combine

/// `League` represents a fantasy league with associated managers, events, and the current user.
/// 
/// - `events`: All events linked to the league's season.
/// - `selectedEvent`: The next upcoming event (if any) based on the current date.
/// - `managers`: The list of managers participating in the league.
/// - `thisUser`: The current user within the league, including their username and money.
/// 
/// The class provides async loading workflows to fetch the current user, managers, and events from network endpoints,
/// automatically selecting the next upcoming event and loading its details.
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
    
    /// Represents the current user in the league.
    ///
    /// - `user_id`: The unique identifier of the user.
    /// - `username`: The username of the user.
    /// - `money`: The current amount of money the user has in the league.
    struct ThisUser: Decodable {
        var user_id: Int
        var username: String
        var money: Int
    }
    
    @Published var thisUser: ThisUser = ThisUser(user_id: -1, username: "Error", money: 0)
    
    /// Loads the league data asynchronously, including the current user, managers, and events.
    ///
    /// - Parameter token: The authentication token used for user-specific requests.
    /// - Returns: A Boolean indicating whether all loading operations succeeded.
    func load(token: String) async -> Bool{
        var success = false
        
        do{
            success = try await self.getThisUser(token: token)
            success = try await self.getManagers()
            success = try await self.getEvents(token: token)
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
    
    /// Asynchronously loads the current user associated with this league.
    ///
    /// - Parameter token: The authentication token required for the request.
    /// - Throws: Propagates decoding or network errors.
    /// - Returns: A Boolean indicating whether the current user was successfully loaded.
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
    
    /// Asynchronously loads the managers participating in the league.
    ///
    /// - Throws: Propagates decoding or network errors.
    /// - Returns: A Boolean indicating whether the managers were successfully loaded.
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
    
    /// Asynchronously loads all events for the league's season, selects the next upcoming event,
    /// attempts to load that event's details, and updates the `selectedEvent`.
    ///
    /// - Throws: Propagates decoding or network errors.
    /// - Returns: A Boolean indicating whether the events and next upcoming event details were successfully loaded.
    func getEvents(token: String) async throws -> Bool{
        let network = Network()
        let response = await network.get(endpoint: "events", queryItems: [URLQueryItem(name: "seasonId", value: "\(season_id)")])
        if response.success{
            let data = response.data
            events = try JSONDecoder().decode([Event].self, from: data!)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            //Get next event
            let now = Date()
            let upcomingNonSprintEvents = self.events.compactMap { event -> (event: Event, date: Date)? in
                guard let date = formatter.date(from: event.event_date),
                      event.is_sprint == 0,  //Ignore sprints
                      date > now
                else {
                    return nil
                }
                return (event, date)
            }
            
            //Set next event
            self.selectedEvent = upcomingNonSprintEvents
                .min { $0.date < $1.date }?
                .event
            
            print(self.selectedEvent ?? "No Event")
            if await self.selectedEvent!.load(leagueId: id, token: token){
                return true
            }
            return false
        }
        return false
    }
    
    
    // Conformance to Equatable
    /// Determines equality between two `League` instances.
    ///
    /// Two leagues are considered equal if they have the same `id` and `name`.
    static func == (lhs: League, rhs: League) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // Conformance to Hashable
    /// Hashes the essential components of the `League`.
    ///
    /// The hash combines the `id` and `name` properties.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}
