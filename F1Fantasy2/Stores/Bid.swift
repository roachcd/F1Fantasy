//
//  Bid.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation

/// A model representing a single bid placed by a manager in an event.
///
///   The `Bid` class captures information about a bid including who placed it,
///   the amount bid, and the timestamp when the bid was created. This model is
///   typically used to display bidding history lists and manage bid data within
///   the application.

class Bid: Codable, Identifiable {
    /// Unique identifier of the bid.
    var id: Int
    
    /// Name of the manager who placed the bid.
    var manager_name: String
    
    /// The amount of the bid.
    var amount: Int
    
    /// The timestamp of when the bid was created, formatted as an ISO 8601 string provided by the backend.
    var created_at: String
}
