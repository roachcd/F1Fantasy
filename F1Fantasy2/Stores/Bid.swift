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
    var id: Int
    var manager_name: String
    var amount: Int
    var created_at: String

    init(id: Int, manager_name: String, amount: Int, created_at: String) {
        self.id = id
        self.manager_name = manager_name
        self.amount = amount
        self.created_at = created_at
    }

    convenience init(amount: Int) {
        self.init(
            id: -1,
            manager_name: "",
            amount: amount,
            created_at: ""
        )
    }
}
