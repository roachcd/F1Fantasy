//
//  TimeoutError.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/19/26.
//

/// An error thrown when an async operation exceeds the allowed time limit.
struct TimeoutError: Error {}

/// /// Runs an asynchronous operation with a timeout.
///
/// This function races the provided operation against a sleep task. If the
/// operation finishes first, its result is returned. If the timeout elapses
/// first, a `TimeoutError` is thrown.
///
/// - Parameters:
///   - duration: The maximum amount of time to wait for the operation.
///   - operation: The asynchronous operation to perform.
/// - Returns: The value produced by the operation if it completes in time.
/// - Throws: A `TimeoutError` if the timeout is reached first, or any error
///   thrown by the operation itself.
///
/// Example:
/// ```swift
/// let value = try await withTimeout(.seconds(2)) {
///     try await fetchData()
/// }
/// ```
func withTimeout<T>(
    _ duration: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError()
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
