//
//  UserData.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import Foundation
internal import Combine

/// An observable app-wide state object that manages authentication,
/// persisted login restoration, and league-related user data.
///
/// `UserData` is intended to be used as a shared source of truth for
/// login state and the current user's league context.
@MainActor
final class UserData: ObservableObject {

    /// Indicates whether the user is currently authenticated.
    @Published var isLoggedIn: Bool = false

    /// The authenticated user's email address.
    @Published var email: String = ""

    /// The current authentication token.
    @Published var token: String = ""

    /// The list of leagues available to the current user.
    @Published var leagues: [League] = []

    /// The currently selected league.
    @Published var selectedLeague: League? = nil

    /// Indicates whether the app is still performing launch-time setup.
    @Published var isLaunching: Bool = true

    /// Network service used for authentication and data requests.
    private let network: Network = Network()
    
    /// Creates a new `UserData` instance and attempts to restore a saved session.
    ///
    /// On initialization, the object checks the keychain for a saved token and
    /// attempts to load the user's leagues. When initialization completes,
    /// `isLaunching` is set to `false`.
    init() {
        Task {
            if await loginFromKeychain() {
                isLoggedIn = true
            }
            isLaunching = false
        }
    }
    
    /// Loads the current user's initial data after authentication.
    ///
    /// - Returns: `true` if user data was loaded successfully; otherwise `false`.
    func load() async -> Bool {
        var success = false
        
        success = await self.getLeagues()
        
        if success {
            return true
        }
        return false
    }
    
    /// Attempts to restore the user's login session from the keychain.
    ///
    /// If a token is found, it is assigned to the current session and used
    /// to fetch the user's leagues.
    ///
    /// - Returns: `true` if login restoration succeeds; otherwise `false`.
    func loginFromKeychain() async -> Bool {
        if let token = KeychainHelper.shared.read(for: "Token") {
            self.token = token
            let success = await getLeagues()
            if !success {
                print("Error getting leagues")
                return false
            } else {
                return true
            }
        }
        return false
    }
    
    /// Logs the user out and clears all user-related state.
    ///
    /// This removes the saved token from the keychain and resets
    /// in-memory authentication and league data.
    func logout() {
        self.token = "None"
        self.isLoggedIn = false
        self.leagues = []
        self.selectedLeague = nil
        KeychainHelper.shared.delete(for: "Token")
    }
    
    /// The response returned by the login endpoint.
    struct LoginResponse: Codable {

        /// The authenticated user's email address.
        let email: String

        /// The authentication token returned by the server.
        let token: String
    }

    /// Attempts to authenticate the user with the provided credentials.
    ///
    /// On success, the returned email and token are stored, the token is saved
    /// to the keychain, and the user's initial data is loaded.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: `true` if login and initial data loading succeed; otherwise `false`.
    func login(email: String, password: String) async -> Bool {
        let response = await network.post(
            endpoint: "login",
            body: ["email": email, "password": password]
        )

        if response.success, let data = response.data {
            let login = try? JSONDecoder().decode(LoginResponse.self, from: data)
            self.email = login?.email ?? ""
            self.token = login?.token ?? ""
            KeychainHelper.shared.save(token, for: "Token")

            if await load() {
                self.isLoggedIn = true
                return true
            }
            return false
        } else {
            print(response.response)
            return false
        }
    }
    
    /// Fetches the leagues available to the current user.
    ///
    /// If leagues are successfully loaded and at least one exists, the first
    /// league is selected and its data is loaded.
    ///
    /// - Returns: `true` if the request succeeds, even if no league is selected;
    ///   otherwise `false`.
    func getLeagues() async -> Bool {
        let response = await network.get(endpoint: "leagues", token: token)

        if response.success {
            do {
                let leagues = try JSONDecoder().decode([League].self, from: response.data!)
                self.leagues = leagues
            } catch {
                print(error)
            }
            
            if let selectedLeague = self.leagues.first {
                let success = await selectedLeague.load(token: token)
                if success {
                    self.selectedLeague = selectedLeague
                    return true
                }
            }
            return true
        } else {
            return false
        }
    }
    
    /// Refreshes the current user's data within the selected league.
    ///
    /// - Returns: `true` if the current user data was updated successfully;
    ///   otherwise `false`.
    ///
    /// - Important: This method assumes `selectedLeague` is not `nil`.
    func updateThisUser() async -> Bool {
        do {
            _ = try await selectedLeague!.getThisUser(token: token)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
