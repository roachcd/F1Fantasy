//
//  Fee.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/24/26.
//

import Foundation

struct Fee {
    static let shared = Fee()
    
    func percent(event: Event) -> Double{
        guard
            let startDate = TimeFormatter.shared.date(from: event.bidding_starts_at),
            let closeDate = TimeFormatter.shared.date(from: event.bidding_closes_at)
        else { return 0 }
        let today = Date()
        if today < startDate { return 0 }
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: closeDate).day ?? 1
        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        let progress = Double(daysElapsed) / Double(totalDays)
        return progress
    }
    
    func fee(event: Event) -> Int {
        guard
            let startDate = TimeFormatter.shared.date(from: event.bidding_starts_at),
            let closeDate = TimeFormatter.shared.date(from: event.bidding_closes_at)
        else { return 0 }

        let today = Date()
        if today < startDate { return 0 }
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: closeDate).day ?? 1
        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        let progress = max(0, min(daysElapsed, totalDays))
        
        return progress * 5
    }
}
