//
//  Bid.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation

class Bid: Codable, Identifiable {
    var id: Int
    var manager_name: String
    var amount: Int
    var created_at: String
}
