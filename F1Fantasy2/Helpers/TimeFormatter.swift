//
//  TimeFormatter.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import Foundation

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
}
