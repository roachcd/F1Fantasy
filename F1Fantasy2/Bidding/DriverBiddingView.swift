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
    @State var showClosedMessage = false
    @State var loading = true
    @State private var refreshTask: Task<Void, Never>?
    @State private var didNotUpdate: Bool = true

    func getBids() async -> Bool{
        do{
            let network = Network()
            let response = await network.get(endpoint: "driverBids", queryItems: [URLQueryItem(name: "eventDriverId", value: "\(driver.event_driver_id)"), URLQueryItem(name: "leagueId", value: "\(userData.selectedLeague!.id)")])
            if response.success{
                bids = try JSONDecoder().decode([Bid].self, from: response.data!)
                print(bids)
                loading = false
                return true
            }
            return false
        }
        catch{
            print(error)
            return false
        }
    }
    
    var closed: Bool {
        guard let date = TimeFormatter.shared.date(from: event.bidding_closes_at) else {
            return false
        }
        return date <= Date()   
    }
    
    private var liveHeader: some View {
        HStack{
            Text("Bidding History")
            Spacer();
            if didNotUpdate {
                ProgressView()
            }
            else{
                Text("Live")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
            }
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

            List {
                Section(header: liveHeader){
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
                        }.foregroundStyle(bid.manager_name == userData.selectedLeague!.thisUser.username ? .blue : .primary)
                    }
                    if bids.isEmpty && !loading{
                        Text("No bids placed yet")
                    }
                    if loading {
                        HStack{
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .task{
                _ = await getBids()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack{
                if closed || userData.selectedLeague!.selectedEvent?.status == 1{
                    EmptyView()
                }
                else if userData.selectedLeague!.thisUser.money == 0 {
                    Text("Out of money")
                }
                else{
                    Picker("$", selection: $selectedBid){
                        ForEach(5...userData.selectedLeague!.thisUser.money, id: \.self) { price in
                            Text("$\(price)")
                                .tag(price)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: .infinity, height: 120)
                    .clipped()
                    Spacer()
                    Button{
                        var closed: Bool {
                            guard let date = TimeFormatter.shared.date(from: event.bidding_closes_at) else {
                                return false
                            }
                            return date <= Date()
                        }
                        if closed{
                            showClosedMessage = true
                        }
                        else{
                            showBidConfirmation = true
                        }
                    }label: {
                        Text("Bid")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 36)
                    }.buttonStyle(.borderedProminent)
                        .alert("Place Bid?", isPresented: $showBidConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Confirm") {
                                Task{
                                    var closed: Bool {
                                        guard let date = TimeFormatter.shared.date(from: event.bidding_closes_at) else {
                                            return false
                                        }
                                        return date <= Date()
                                    }
                                    if closed{
                                        showClosedMessage = true
                                    }
                                    else{
                                        let network = Network()
                                        let response = await network.post(endpoint: "placeBid", body: ["token": userData.token, "event_driver_id": driver.event_driver_id, "league_id": "\(userData.selectedLeague!.id)", "amount": "\(selectedBid)"])
                                        if response.success{
                                            userData.selectedLeague!.thisUser.money -= selectedBid
                                            _ = await getBids()
                                        }
                                    }
                                }
                            }
                        } message: {
                            Text("Are you sure you want to bid $\(selectedBid) on \(driver.name)?")
                        }
                }
            }.padding()
                .alert("Bidding Closed", isPresented: $showClosedMessage) {
                    Button("Ok", role: .cancel) { }
                } message: {
                    Text("Bidding has been closed.")
                }
        }
        .onAppear {
            startAutoRefresh()
        }
        .onDisappear {
            refreshTask?.cancel()
        }
    }
    private func startAutoRefresh() {
        refreshTask?.cancel()

        refreshTask = Task {
            while !Task.isCancelled {
                do{
                    let success = try await withTimeout(.seconds(1)) {
                        await getBids()
                    }
                    if success{
                        didNotUpdate = false
                    }
                    else{
                        didNotUpdate = true
                    }
                }catch{
                    didNotUpdate = true
                    print(error)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
