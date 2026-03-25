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
    @Published var leagues: [League] = []
    @Published var selectedLeague: League? = nil
    @Published var isLaunching: Bool = true
    private let network: Network = Network()
    
    init(){
        Task{
            if await loginFromKeychain(){
                isLoggedIn = true
            }
            isLaunching = false
        }
    }
    
    func load() async -> Bool{
        var success = false
        
        success = await self.getLeagues()
        
        if success{
            return true
        }
        return false
    }
    
    func loginFromKeychain() async -> Bool{
        if let token = KeychainHelper.shared.read(for: "Token"){
            self.token = token
            let success = await getLeagues()
            if !success {
                print("Error getting leagues")
                return false
            }
            else{
                return true
            }
        }
        return false
    }
    
    func logout(){
        self.token = "None"
        self.isLoggedIn = false
        self.leagues = []
        self.selectedLeague = nil
        KeychainHelper.shared.delete(for: "Token")
    }
    
    
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
            KeychainHelper.shared.save(token, for: "Token")

            if await load(){
                self.isLoggedIn = true
                return true
            }
            return false
        }
        else{
            print(response.response)
            return false
        }
    }
    
    func getLeagues() async -> Bool{
        let response = await network.get(endpoint: "leagues", token: token)
        if response.success{
            do{
                let leagues = try JSONDecoder().decode([League].self, from: response.data!)
                self.leagues = leagues
            }
            catch {
                print(error)
            }
            
            if let selectedLeague = self.leagues.first{
                let success = await selectedLeague.load(token: token)
                if success{
                    self.selectedLeague = selectedLeague
                    return true
                }
            }
            return true
        }
        else{
            return false
        }
    }
    
    func updateThisUser() async -> Bool{
        do{
            _ = try await selectedLeague!.getThisUser(token: token)
            return true
        }
        catch{
            print(error)
            return false
        }
    }
}
