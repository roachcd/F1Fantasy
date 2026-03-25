//
//  Fee.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/24/26.
//

import Foundation

struct Fee {
    static let shared = Fee()
    
    //[Days before close : percent]
    var percent: [Int:Double] = [
        3 : 0.05,
        2 : 0.10,
        1 : 0.20,
        0 : 0.40
    ]
    
    func percent(event: Event) -> Double {
        guard
            let closeDate = TimeFormatter.shared.date(from: event.bidding_closes_at)
        else { return 0 }
        let today = Date()
        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: closeDate).day ?? 0
        let clamped = max(0, min(daysRemaining, 3)) // limit to 0–3
        return (percent[clamped] ?? 0) * 100
    }
    
    func fee(event: Event, amount: Int) -> Int {
        guard
            let closeDate = TimeFormatter.shared.date(from: event.bidding_closes_at)
        else { return 0 }
        let today = Date()
        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: closeDate).day ?? 0
        let clamped = max(0, min(daysRemaining, 3))
        return Int(Double(amount) * (percent[clamped] ?? 0))
    }
}
