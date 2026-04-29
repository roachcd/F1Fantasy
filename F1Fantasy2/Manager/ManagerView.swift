//
//  ManagerView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/18/26.
//

import SwiftUI

/// A view that displays detailed information about a manager.
///
/// - Parameters:
///   - manager: The manager whose details are to be displayed.
///   - userData: An observed object containing user-related data, including selected league and event.
///
struct ManagerView: View{
    var manager: Manager
    @ObservedObject var userData: UserData
    @ObservedObject var event: Event
    
    var body: some View{
        List{
            Text(manager.username).font(.title2).listRowSeparator(.hidden)
            if let league = userData.selectedLeague{
                ManagerLineupList(manager: manager, league: league, event: event, userData: userData)
            }
        }
    }
}
