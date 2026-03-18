//
//  ManagerView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/18/26.
//

import SwiftUI

struct ManagerView: View{
    var manager: Manager
    var league: League
    var event: Event
    @ObservedObject var userData: UserData
    
    var body: some View{
        List{
            Text(manager.username).font(.title2).listRowSeparator(.hidden)
            ManagerLineupList(manager: manager, league: league, event: event, userData: userData)
        }
    }
}
