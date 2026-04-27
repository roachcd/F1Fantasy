import Foundation
internal import Combine

@MainActor
final class Driver: Identifiable, Hashable, Codable, ObservableObject {
    
    let id = UUID()

    var driver_id: Int
    var event_driver_id: Int
    var name: String
    var car_number: Int
    var team: String
    var position: Int
    var points: Int
    var cost: Int

    @Published var bid: Bid?

    var event_id: Int = -1

    enum CodingKeys: String, CodingKey {
        case driver_id
        case event_driver_id
        case name
        case car_number
        case team
        case position
        case points
        case cost
        case bid
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        driver_id = try container.decode(Int.self, forKey: .driver_id)
        event_driver_id = try container.decode(Int.self, forKey: .event_driver_id)
        name = try container.decode(String.self, forKey: .name)
        car_number = try container.decode(Int.self, forKey: .car_number)
        team = try container.decode(String.self, forKey: .team)
        position = try container.decode(Int.self, forKey: .position)
        points = try container.decode(Int.self, forKey: .points)
        cost = try container.decode(Int.self, forKey: .cost)

        bid = try container.decodeIfPresent(Bid.self, forKey: .bid)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(driver_id, forKey: .driver_id)
        try container.encode(event_driver_id, forKey: .event_driver_id)
        try container.encode(name, forKey: .name)
        try container.encode(car_number, forKey: .car_number)
        try container.encode(team, forKey: .team)
        try container.encode(position, forKey: .position)
        try container.encode(points, forKey: .points)
        try container.encode(cost, forKey: .cost)
        try container.encodeIfPresent(bid, forKey: .bid)
    }

    func getDriverBid(token: String, leagueId: Int) async throws -> Bool {
        do {
            let network = Network()
            let response = await network.get(
                endpoint: "userDriverBid",
                queryItems: [
                    URLQueryItem(name: "eventDriverId", value: "\(event_driver_id)"),
                    URLQueryItem(name: "leagueId", value: "\(leagueId)"),
                    URLQueryItem(name: "token", value: token)
                ]
            )

            if response.success, let data = response.data {
                let bids = try JSONDecoder().decode([Bid].self, from: data)
                bid = bids.first
                print(bid?.amount as Any)
                return true
            }

            return false
        } catch {
            print(error)
            return false
        }
    }

    static func == (lhs: Driver, rhs: Driver) -> Bool {
        lhs.driver_id == rhs.driver_id &&
        lhs.event_driver_id == rhs.event_driver_id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(driver_id)
        hasher.combine(event_driver_id)
    }
}
