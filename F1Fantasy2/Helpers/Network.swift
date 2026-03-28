//
//  Network.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 3/3/26.
//

import Foundation

/// A lightweight networking utility for performing HTTP requests
/// against the app's configured backend.
///
/// Supports basic GET and POST requests with optional authentication.
///
/// Usage:
/// ```swift
/// let network = Network()
/// let response = await network.get(endpoint: "users")
/// ```
class Network {
    /// Base URL for all API requests.
    let url = Config.baseURL;
    
    /// A standardized response wrapper for network calls.
    struct Response{
        /// Raw response data returned from the server.
        let data: Data?;
        
        /// The URL response metadata
        let response: URLResponse;
        
        /// Indicates whether the request was successful
        let success: Bool;
    }
    
    // MARK: - GET

    /// Performs a GET request to the specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint (appended to the base URL).
    ///   - queryItems: Optional query parameters to include in the request.
    ///   - token: Optional bearer token for authenticated requests.
    ///
    /// - Returns: A `Response` object containing data, metadata, and success flag.
    ///
    
    func get(endpoint: String, queryItems: [URLQueryItem]? = nil, token: String? = nil) async -> Response{
        var components = URLComponents(string: "\(url)/\(endpoint)")!
        components.queryItems = queryItems;
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if token != nil, let token = token{
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            guard status == 200 || status == 201 else {
                throw URLError(.badServerResponse)
            }
            return Response(data: data, response: response, success: true)
        } catch {
            print("Error:", error)
            return Response(data: nil, response: URLResponse(), success: false)
        }
    }
    
    // MARK: - POST

    /// Performs a POST request to the specified endpoint with a JSON body.
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint (appended to the base URL).
    ///   - body: A dictionary representing the JSON payload.
    ///
    /// - Returns: A `Response` object containing data, metadata, and success flag.

    func post(endpoint: String, body: [String : Any]) async -> Response{
        let reqUrl = URL(string: "\(url)/\(endpoint)")!
        // Create request
        var request = URLRequest(url: reqUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
        // Request body
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            if status == 200 || status == 201 { return Response(data: data, response: response, success: true)}
            print(String(data: data, encoding: .utf8) ?? "Unkown Error")
            return Response(data: nil, response: response, success: false)
        } catch {
            print(error)
            return Response(data: nil, response: URLResponse(), success: false)
        }
    }
}
