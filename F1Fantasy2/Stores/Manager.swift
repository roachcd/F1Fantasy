//
//  Manager.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

import SwiftUI

/// Represents a manager in the system, including identity and scoring data.
///
/// `Manager` is a reference type that conforms to `Identifiable`, `Hashable`,
/// and `Codable`, making it suitable for use in SwiftUI lists, collections,
/// and network serialization.
@MainActor
final class Manager: Identifiable, Hashable, Codable {

    /// Unique identifier for the manager.
    var id: Int

    /// The manager's username.
    var username: String

    /// The manager's current points or score.
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
