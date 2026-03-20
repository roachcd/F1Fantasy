//
//  HomeView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var userData: UserData
    @State private var selectedTab = 0
    @State var eventSheet: Bool = false
    
    var body: some View {
        if #available(iOS 26.0, *){
            tabBar
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    if let selectedLeague = userData.selectedLeague{
                        AccessoryView(selectedLeague: selectedLeague)
                    }
                }
        }
        else{
            tabBar
        }
    }

    struct AccessoryView: View {
        @ObservedObject var selectedLeague: League

        var body: some View {
            HStack {
                if selectedLeague.selectedEvent?.status == 1 {
                    Image(systemName: "lock.fill")
                    Text("This event is locked")
                } else if selectedLeague.selectedEvent?.status == 2 {
                    Image(systemName: "lock.open.fill")
                    CountdownText(timestamp: selectedLeague.selectedEvent!.bidding_closes_at)
                    Spacer()
                    Text("$\(selectedLeague.thisUser.money)")
                } else if selectedLeague.selectedEvent?.status == 3 {
                    Image(systemName: "flag.pattern.checkered.2.crossed")
                    Text("This event is finished")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
    
    private var tabBar: some View {
        TabView(selection: $selectedTab) {
            LeagueView(userData: userData)
                .tabItem { Label("League", systemImage: "chart.bar.fill") }
                .tag(0)
            
            if let event = userData.selectedLeague?.selectedEvent{
                BiddingListView(league: userData.selectedLeague!, event: event, userData: userData)
                    .tabItem { Label("Bidding", systemImage: "flag.pattern.checkered") }
                    .tag(1)
            }

            ExtraGameView()
                .tabItem { Label("Extra", systemImage: "list.bullet") }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                leagueMenu
            }
            ToolbarItem(placement: .topBarLeading) {
                if let league = userData.selectedLeague{
                    EventToolbarButton(league: league, eventSheet: $eventSheet)
                }
            }
        }
        .sheet(isPresented: $eventSheet){
            if let league = userData.selectedLeague{
                EventIndicatorMenu(league: league)
            }
        }
        .onChange(of: selectedTab){
            Task{
                _ = await userData.selectedLeague!.selectedEvent!.load()
            }
        }
    }
    
    private var leagueMenu: some View {
        Menu {
            HStack{
                NavigationLink {
                    AccountView(userData: userData)
                } label: {
                    Label("Account", systemImage: "person.fill")
                }
                NavigationLink {
                    //JoinLeague()
                } label: {
                    Label("Join League", systemImage: "plus.app.fill")
                }
            }
            Section{
                ForEach(userData.leagues, id: \.id) { league in
                    Button {
                        Task{
                            DispatchQueue.main.async {
                                userData.selectedLeague = league
                                selectedTab = 0
                            }
                        }
                    } label: {
                        Text(league.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                if let selectedLeague = userData.selectedLeague {
                    Text(selectedLeague.name)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                else{
                    Text("Error")
                }
            }
        }
        .applyGlassButtonStyleIfAvailable() //Apply .bottonStyle(.glass) on 26
    }

    struct EventToolbarButton: View {
        @ObservedObject var league: League
        @Binding var eventSheet: Bool
        
        var body: some View {
            Button {
                eventSheet = true
            } label: {
                Text(league.selectedEvent?.name ?? "Select Event")
            }
        }
    }
    

    struct EventIndicatorMenu: View {
        @Environment(\.dismiss) var dismiss
        @ObservedObject var league: League

        var body: some View {
            List {
                ForEach(league.events, id: \.id){event in
                    Button{
                        league.selectedEvent = event
                        dismiss()
                        Task{
                            await event.load()
                            league.selectedEvent = event
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(event.country)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 6) {
                                    Image(systemName: statusIcon(for: event.status))
                                    Text(statusText(for: event.status))
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        func statusText(for status: Int) -> String {
            switch status {
            case 2: return "Unlocked"
            case 1: return "Locked"
            case 3: return "Finished"
            default: return "Unknown"
            }
        }

        func statusIcon(for status: Int) -> String {
            switch status {
            case 2: return "lock.open.fill"
            case 1: return "lock.fill"
            case 3: return "flag.checkered"
            default: return "questionmark.circle"
            }
        }
    }
}

private struct BiddingViewPlaceholder: View {
    var body: some View {
        ContentUnavailableView("No Event Selected", systemImage: "flag.pattern.checkered", description: Text("Choose an event from the League menu."))
    }
}
