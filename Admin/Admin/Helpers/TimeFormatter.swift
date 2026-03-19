//
//  TimeFormatter.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation
import SwiftUI

final class TimeFormatter {
    static let shared = TimeFormatter()

    private let input: ISO8601DateFormatter
    private let output: DateFormatter

    private init() {
        input = ISO8601DateFormatter()
        input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        output = DateFormatter()
        output.dateFormat = "h:mma"
        output.locale = Locale(identifier: "en_US_POSIX")
    }

    func format(_ timestamp: String) -> String {
        guard let date = input.date(from: timestamp) else {
            print("FAILED TO PARSE:", timestamp)
            return timestamp
        }
        return output.string(from: date)
    }
    
    func date(from timestamp: String) -> Date? {
        input.date(from: timestamp)
    }

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

struct AdaptiveCountdownSchedule: TimelineSchedule {
    let targetDate: Date

    func entries(from startDate: Date, mode: Mode) -> Entries {
        Entries(startDate: startDate, targetDate: targetDate)
    }

    struct Entries: Sequence, IteratorProtocol {
        var current: Date
        let targetDate: Date

        init(startDate: Date, targetDate: Date) {
            self.current = startDate
            self.targetDate = targetDate
        }

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
