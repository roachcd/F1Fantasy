//
//  TimeFormatter.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation
import SwiftUI

/// A shared utility for parsing, formatting, and displaying time values.
///
/// `TimeFormatter` converts ISO 8601 timestamp strings into `Date` values,
/// formats dates into display-friendly time strings, and generates countdown text.
final class TimeFormatter {
    
    /// Singleton for TimeFormatter
    static let shared = TimeFormatter()

    /// Formatter used to parse incoming ISO 8601 timestamps.
    private let input: ISO8601DateFormatter
    
    /// Formatter used to generate user-facing time strings.
    private let output: DateFormatter

    /// Creates a configured formatter instance.
    ///
    /// The input formatter supports internet date-time strings with fractional seconds.
    /// The output formatter displays times in `h:mma` format, such as `3:45PM`.
    private init() {
        input = ISO8601DateFormatter()
        input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        output = DateFormatter()
        output.dateFormat = "h:mma"
        output.locale = Locale(identifier: "en_US_POSIX")
    }

    /// Formats an ISO 8601 timestamp string into a user-facing time string.
    ///
    /// - Parameter timestamp: A timestamp string in ISO 8601 format.
    /// - Returns: A formatted time string, or the original timestamp if parsing fails.
    ///
    /// Example:
    /// ```swift
    /// let value = TimeFormatter.shared.format("2026-03-28T18:30:00.000Z")
    /// ```
    func format(_ timestamp: String) -> String {
        guard let date = input.date(from: timestamp) else {
            print("FAILED TO PARSE:", timestamp)
            return timestamp
        }
        return output.string(from: date)
    }
    
    /// Converts an ISO 8601 timestamp string into a `Date`.
    ///
    /// - Parameter timestamp: A timestamp string in ISO 8601 format.
    /// - Returns: A `Date` if parsing succeeds, otherwise `nil`.
    func date(from timestamp: String) -> Date? {
        input.date(from: timestamp)
    }

    /// Returns a human-readable countdown string between two dates.
    ///
    /// The output adapts based on remaining time:
    /// - `"Closed"` when the time has elapsed
    /// - `"X day"` or `"X days"` when at least one day remains
    /// - `"Xh Ym"` when at least one hour remains
    /// - `"Xm Ys"` when less than one hour remains
    ///
    /// - Parameters:
    ///   - date: The target end date.
    ///   - now: The current date used for comparison.
    /// - Returns: A display string representing the remaining time.
    func timeRemaining(until date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))

        if seconds <= 0 {
            return "Closed"
        }

        let days = seconds / 86_400
        if days >= 1 {
            return "\(days) day" + (days == 1 ? "" : "s")
        }

        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60

        if hours >= 1 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m \(secs)s"
        }
    }
}

/// A timeline schedule that updates more frequently as a target date approaches.
///
/// Update frequency is based on time remaining:
/// - Daily when more than 24 hours remain
/// - Every minute when more than 1 hour remains
/// - Every second when less than 1 hour remains
struct AdaptiveCountdownSchedule: TimelineSchedule {
    /// The date the countdown is targeting.
    let targetDate: Date

    /// Creates the sequence of timeline entries beginning at the provided start date.
    ///
    /// - Parameters:
    ///   - startDate: The starting date for timeline generation.
    ///   - mode: The timeline mode supplied by SwiftUI.
    /// - Returns: A sequence of timeline dates.
    func entries(from startDate: Date, mode: Mode) -> Entries {
        Entries(startDate: startDate, targetDate: targetDate)
    }

    /// A sequence and iterator that generates adaptive timeline update dates.
    struct Entries: Sequence, IteratorProtocol {
        /// The current timeline position.
        var current: Date
        
        /// The final countdown target date.
        let targetDate: Date

        /// Creates a new iterator for countdown entries.
        ///
        /// - Parameters:
        ///   - startDate: The current date from which updates begin.
        ///   - targetDate: The date the countdown ends.
        init(startDate: Date, targetDate: Date) {
            self.current = startDate
            self.targetDate = targetDate
        }

        /// Returns the next update date in the sequence.
        ///
        /// - Returns: The next scheduled update date, or `nil` after the target date is reached.
        mutating func next() -> Date? {
            if current >= targetDate {
                return nil
            }

            let result = current
            let remaining = targetDate.timeIntervalSince(current)

            if remaining > 86_400 {
                current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? targetDate
            } else if remaining > 3_600 {
                current = Calendar.current.date(byAdding: .minute, value: 1, to: current) ?? targetDate
            } else {
                current = Calendar.current.date(byAdding: .second, value: 1, to: current) ?? targetDate
            }

            return result
        }
    }
}

/// A SwiftUI view that displays a live countdown for a timestamp.
///
/// If the timestamp can be parsed, the view updates automatically using
/// `TimelineView` and `AdaptiveCountdownSchedule`. If parsing fails,
/// the raw timestamp string is displayed instead.
struct CountdownText: View {
    let timestamp: String

    var body: some View {
        if let targetDate = TimeFormatter.shared.date(from: timestamp) {
            TimelineView(AdaptiveCountdownSchedule(targetDate: targetDate)) { context in
                Text(TimeFormatter.shared.timeRemaining(until: targetDate, now: context.date))
            }
        } else {
            Text(timestamp)
        }
    }
}
