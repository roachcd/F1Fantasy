//
//  Network.swift
//  F1FantasyIOS
//
//  Created by Chase Roach on 3/3/26.
//

import Foundation

class Network {
    let url = Config.baseURL;
    
    struct Response{
        let data: Data?;
        let response: URLResponse;
        let success: Bool;
    }
    
    //GET DATA
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
            guard status == 200 else {
                throw URLError(.badServerResponse)
            }
            return Response(data: data, response: response, success: true)
        } catch {
            print("Error:", error)
            return Response(data: nil, response: URLResponse(), success: false)
        }
    }
    
    //POST DATA
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
            print(String(data: data, encoding: .utf8))
            return Response(data: nil, response: response, success: false)
        } catch {
            print(error)
            return Response(data: nil, response: URLResponse(), success: false)
        }
    }
}
