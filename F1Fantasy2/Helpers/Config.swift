//
//  Config.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 2/28/26.
//

import Foundation

/// A helper class to define API hosts depending on if the app is in development or production mode

struct Config {
    
    /// Change mode for development or production
    static let mode = 1 // 0 = development, 1 = production
    
    static let endpoints: [Int: String] = [
        0: "http://localhost:3000",
        1: "https://f1fantasy-akzi.onrender.com"
    ]
    
    static var baseURL: String {
        endpoints[mode]!
    }
}
