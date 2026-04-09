//
//  HomeView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//


import SwiftUI

/// The main home view presenting a tabbed layout with three tabs: League, Bidding, and Extra.
/// 
/// - Parameters:
///     - userData: An observed object containing user-related data including selected league.
///     - State: Maintains the currently selected tab and the event sheet presentation state.
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

    /// A bottom accessory view displayed below the tab bar showing the status of the selected event,
    /// including lock status, countdown, or finished indicator.
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
    
    /// Builds the main tab view with tabs for League, Bidding, and Extra sections.
    /// Handles top toolbar items including the league menu and event button,
    /// and manages the presentation of the event selection sheet.
    private var tabBar: some View {
        TabView(selection: $selectedTab) {
            LeagueView(userData: userData)
                .tabItem { Label("League", systemImage: "chart.bar.fill") }
                .tag(0)
            
            if let event = userData.selectedLeague?.selectedEvent{
                DriverSelectionView(userData: userData, event: event, league: userData.selectedLeague!)
                    .tabItem {
                        Label(event.is_sprint == 1 ? "Bidding" : "Lineup",
                              systemImage: "flag.pattern.checkered")
                    }
                    .tag(1)
                    .id(event.id)
            }

            ExtraGameView()
                .tabItem { Label("Extra", systemImage: "list.bullet") }
                .tag(3)
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
                _ = await userData.selectedLeague!.selectedEvent!.load(leagueId: userData.selectedLeague!.id)
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
                    JoinLeagueView(userData: userData)
                } label: {
                    Label("Join League", systemImage: "plus.app.fill")
                }
            }
            Section{
                ForEach(userData.leagues, id: \.id) { league in
                    Button {
                        Task{
                            _ = await league.load(token: userData.token)
                            userData.selectedLeague = league
                            selectedTab = 0
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

    /// A button displayed in the toolbar allowing the user to open the event selection sheet.
    struct EventToolbarButton: View {
        @ObservedObject var league: League
        @Binding var eventSheet: Bool
        
        var body: some View {
            Button {
                eventSheet = true
            } label: {
                HStack(spacing: 4){
                    Text(league.selectedEvent?.name ?? "Select Event")
                        if league.selectedEvent?.is_sprint == 1 {
                            Text("Sprint")
                        } else {
                            Text("Grand Prix")
                        }
                }
            }
        }
    }
    

    /// A menu list presented as a sheet allowing the user to select an event from the league's events.
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
                            await event.load(leagueId: league.id)
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
                                HStack{
                                    Text(event.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Group{
                                        if event.is_sprint == 1 {
                                            Text("Sprint")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gray.opacity(0.25))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        } else {
                                            Text("Grand Prix")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }
                                }
                                
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
        /// Returns a user-friendly status text for a given event status code.
        /// - Parameter status: The event status code.
        /// - Returns: A string describing the status (e.g., "Unlocked", "Locked", "Finished", or "Unknown").
        func statusText(for status: Int) -> String {
            switch status {
            case 2: return "Unlocked"
            case 1: return "Locked"
            case 3: return "Finished"
            default: return "Unknown"
            }
        }

        /// Returns the system image name corresponding to a given event status code.
        /// - Parameter status: The event status code.
        /// - Returns: A string representing the SF Symbol name for the status icon.
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
