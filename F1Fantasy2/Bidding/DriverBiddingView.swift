//
//  BiddingView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/17/26.
//

import SwiftUI

struct DriverBiddingView: View {
    @ObservedObject var event: Event
    @ObservedObject var userData: UserData
    var driver: Driver
    @State private var selectedBid: Int = 5
    let priceRange = 5...50
    @State var bids: [Bid] = []
    @State var showBidConfirmation = false
    
    func getBids() async -> Bool{
        do{
            let network = Network()
            let response = await network.get(endpoint: "driverBids", queryItems: [URLQueryItem(name: "eventDriverId", value: "\(driver.event_driver_id)"), URLQueryItem(name: "leagueId", value: "\(userData.selectedLeague!.id)")])
            if response.success{
                bids = try JSONDecoder().decode([Bid].self, from: response.data!)
                print(bids)
                return true
            }
            return false
        }
        catch{
            print(error)
            return false
        }
    }
    
    var body: some View {
        VStack{
            HStack(spacing: 15){
                Image("\(driver.name)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(.secondary, lineWidth: 2)
                    )
                Text(driver.name).font(Font.largeTitle)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bidding History")
                    .font(.headline)

                List {
                    HStack {
                        Text("Manager")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Bid")
                            .frame(width: 70, alignment: .trailing)
                        Text("Time")
                            .frame(width: 120, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach(bids.reversed()) { bid in
                        HStack {
                            Text(verbatim: bid.manager_name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(bid.amount, format: .currency(code: "USD"))
                                .frame(width: 70, alignment: .trailing)
                            Text(TimeFormatter.shared.format(bid.created_at))
                                .frame(width: 120, alignment: .trailing)
                        }//.foregroundStyle(bid.manager_name == userData.userId ? .blue : .primary)
                    }
                    if bids.isEmpty{
                        Text("No bids placed yet")
                    }
                }
                .listStyle(.plain)
                .task{
                    _ = await getBids()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack{
                Picker("$", selection: $selectedBid){
                    ForEach(priceRange, id: \.self) { price in
                        Text("$\(price)")
                            .tag(price)
                    }
                }
                    .pickerStyle(.wheel)
                    .frame(width: .infinity, height: 120)
                    .clipped()
                Spacer()
                Button{
                    showBidConfirmation = true
                }label: {
                    Text("Bid")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 36)
                }.buttonStyle(.borderedProminent)
                    .alert("Place Bid?", isPresented: $showBidConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Confirm") {
                            Task{
                                let network = Network()
                                let response = await network.post(endpoint: "placeBid", body: ["token": userData.token, "event_driver_id": driver.event_driver_id, "league_id": "\(userData.selectedLeague!.id)", "amount": "\(selectedBid)"])
                                if response.success{
                                    _ = await getBids()
                                }
                            }
                        }
                    } message: {
                        Text("Are you sure you want to bid $\(selectedBid) on \(driver.name)?")
                    }
            }.padding()
        }
    }
}
