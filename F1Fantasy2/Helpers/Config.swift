//
//  Config.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 2/28/26.
//

import Foundation

struct Config {
    static let mode = 1 // 0 = development, 1 = production
    
    static let endpoints: [Int: String] = [
        0: "http://localhost:3000",
        1: "https://f1fantasy-akzi.onrender.com"
    ]
    
    static var baseURL: String {
        endpoints[mode]!
    }
}
