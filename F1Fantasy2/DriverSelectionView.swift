//
//  DriverSelectionView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 4/9/26.
//

/// A container for BiddingListView and MyLineupView, conditionally selects
/// BiddingListView and MyLineupView based on if the event is a sprint or
/// not
///
/// - Parameters:
///     - userData: An observed object containing user-related data.
///     - Event: An observed object of the selected event.
///     - League: An observed object of the selected league.

import SwiftUI

struct DriverSelectionView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var event: Event
    @ObservedObject var league: League
    
    var body: some View {
        VStack {
            if event.is_sprint == 1{
                BiddingListView(league: league, event: event, userData: userData)
            }
            else{
                MyLineupView()
            }
        }
    }
}
