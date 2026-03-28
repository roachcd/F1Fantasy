//
//  Fee.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/24/26.
//

import Foundation

/// A utility for calculating fee percentages and fee amounts
/// based on how many days remain before an event's bidding closes.
///
/// Usage:
/// ```swift
/// let percent = Fee.shared.percent(event: event)
/// let fee = Fee.shared.fee(event: event, amount: 100)
/// ```

struct Fee {
    /// Singleton for Fee
    static let shared = Fee()
    
    /// Mapping of days remaining before bidding closes to fee percentage.
    ///
    /// - Key: Number of days remaining (0–3)
    /// - Value: Fee percentage expressed as a decimal (e.g., `0.05` = 5%)
    var percent: [Int:Double] = [
        3 : 0.00,
        2 : 0.00,
        1 : 0.00,
        0 : 0.00
    ]
    
    /// Calculates the fee percentage for a given event.
    ///
    /// The result is based on how many days remain until the event's
    /// `bidding_closes_at` date. The value is clamped between 0 and 3 days.
    ///
    /// - Parameter event: The event containing the closing date.
    /// - Returns: The fee percentage as a whole number (e.g., `5.0` for 5%).
    ///
    /// - Important: Returns `0` if the event date cannot be parsed.
    func percent(event: Event) -> Double {
        guard
            let closeDate = TimeFormatter.shared.date(from: event.bidding_closes_at)
        else { return 0 }
        let today = Date()
        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: closeDate).day ?? 0
        let clamped = max(0, min(daysRemaining, 3)) // limit to 0–3
        return (percent[clamped] ?? 0) * 100
    }
    
    /// Calculates the fee amount for a given event and base amount.
    ///
    /// The fee is derived from the number of days remaining until the event closes.
    ///
    /// - Parameters:
    ///   - event: The event containing the closing date.
    ///   - amount: The base amount the fee will be applied to.
    ///
    /// - Returns: The calculated fee as an integer.
    ///
    /// - Note: The result is truncated to an `Int`.
    /// - Important: Returns `0` if the event date cannot be parsed.
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
