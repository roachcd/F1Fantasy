//
//  UserData.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import Foundation
internal import Combine

@MainActor
final class UserData: ObservableObject{
    @Published var isLoggedIn: Bool = false
    @Published var email: String = ""
    @Published var token: String = ""
    private let network: Network = Network()
    
    struct LoginResponse: Codable {
        let email: String
        let token: String
    }
    func login(email: String, password: String) async -> Bool{
        let response = await network.post(endpoint: "login", body: ["email": email, "password": password])
        if response.success, let data = response.data {
            let login = try? JSONDecoder().decode(LoginResponse.self, from: data)
            self.email = login?.email ?? ""
            self.token = login?.token ?? ""
            self.isLoggedIn = true
            return true
        }
        else{
            print(response.response)
            return false
        }
    }
}
