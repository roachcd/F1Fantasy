//
//  Manager.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

import SwiftUI

@MainActor
final class Manager: Identifiable, Hashable, Codable {
    var id: Int
    var username: String
    var points: Int
    
    // Conformance to Equatable
    static func == (lhs: Manager, rhs: Manager) -> Bool {
        return lhs.id == rhs.id
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
