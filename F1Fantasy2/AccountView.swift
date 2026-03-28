//
//  AccountView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import SwiftUI
/// A view that displays information about the logged in user.
///
/// - Parameters:
///   - userData: An observed object containing user-related data, including selected league and event.
///
struct AccountView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Account View")
        Button{
            userData.logout()
            dismiss()
        } label: {
            Text("Logout")
        }
    }
}
