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
    
    // Conformance to Equatable
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
