//
//  LeagueView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct LeagueView: View {
    @ObservedObject var userData: UserData
    var body: some View {
        ManagersList(userData: userData)
    }
}
