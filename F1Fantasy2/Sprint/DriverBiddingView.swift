//
//  BiddingView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import SwiftUI

/// A view that displays bidding information and allows placing bids on a specific driver.
///
/// - Displays a list of past bids (bidding history) for the driver.
/// - Shows a live update indicator when the event is open and live.
/// - Provides a picker to select a bid amount if bidding is open and conditions allow.
/// - Handles the bid confirmation flow including bid placement and fee information.
///
/// - Parameters:
///   - event: The event containing bidding details.
///   - userData: User-related data including league and user info.
///   - driver: The driver for whom bids are displayed and placed.
struct DriverBiddingView: View {
    @ObservedObject var event: Event
    @ObservedObject var userData: UserData
    var driver: Driver
    @State var showBidConfirmation: Bool = false
    @State var showBidError: Bool = false
    @State var selectedBid = 5;
    @Environment(\.dismiss) var dismiss
    
    /// Fetches all bids for the current driver within the selected league asynchronously
    /// and updates the local `bids` state and loading indicator.
    ///
    /// - Returns: A Boolean indicating whether the fetch was successful.
 
    var body: some View {
        ScrollView{
            Section{
                VStack(alignment: .center){
                    Image("\(driver.name)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(.secondary, lineWidth: 2)
                        )
                    Text(driver.name).font(.largeTitle).bold().padding(5)
                    HStack{
                        Text(driver.team).font(Font.title2).bold()
                        Text("#\(driver.car_number)").font(Font.title2)
                    }
                }
            }.padding(25)
            HStack{
                if driver.bid == nil {
                    if event.budget >= 5{
                        Picker("$", selection: $selectedBid){
                            ForEach(5...event.budget, id: \.self) { price in
                                Text("$\(price)")
                                    .tag(price)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: .infinity, height: 140)
                        .clipped()
                        Spacer()
                        Button{
                            showBidConfirmation = true;
                        } label: {
                            Text("Bid")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 36)
                        }
                        .buttonStyle(.borderedProminent)
                        .alert("Place Bid?", isPresented: $showBidConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Confirm") {
                                Task{
                                    let network = Network()
                                    let response = await network.post(endpoint: "placeBid", body: ["token": userData.token, "event_driver_id": driver.event_driver_id, "league_id": "\(userData.selectedLeague!.id)", "amount": "\(selectedBid)"])
                                    if response.success{
                                        dismiss()
                                        await event.load(leagueId: userData.selectedLeague!.id, token: userData.token)
                                        driver.bid = Bid(amount: selectedBid)
                                    }
                                    else{
                                        showBidError = true;
                                    }
                                }
                            }
                        } message: {
                            Text("Are you sure you want to bid $\(selectedBid) on \(driver.name)?")
                        }
                        .alert("There was an error placing your bid. Please try again later.", isPresented: $showBidError){
                            Button("Ok", role: .cancel) { }
                        }
                    }
                    else{
                        Text("You must have at least $5 to bid.")
                    }
                }
            }
            .padding()
        }
    }
}
