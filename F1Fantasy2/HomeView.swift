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
    
    var body: some View {
        if let selectedLeague = userData.selectedLeague{
            if #available(iOS 26.0, *){
                tabBar(userData: userData, league: selectedLeague)
                    .tabBarMinimizeBehavior(.onScrollDown)
                    .tabViewBottomAccessory {
                        AccessoryView(league: selectedLeague)
                    }
            }
            else{
                tabBar(userData: userData, league: selectedLeague)
            }
        }
    }

    /// A bottom accessory view displayed below the tab bar showing the status of the selected event,
    /// including lock status, countdown, or finished indicator.
    struct AccessoryView: View {
        @ObservedObject var league: League

        var body: some View {
            HStack {
                if league.selectedEvent!.status == 1 {
                    Image(systemName: "lock.fill")
                    Text("This event is locked")
                } else if league.selectedEvent!.status == 2 {
                    Image(systemName: "lock.open.fill")
                    CountdownText(timestamp: league.selectedEvent!.bidding_closes_at)
                    Spacer()
                    Text("$\(league.selectedEvent!.budget)")
                } else if league.selectedEvent!.status == 3 {
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
    struct tabBar: View {
        @ObservedObject var userData: UserData
        @ObservedObject var league: League
        @State var eventSheet: Bool = false
        @State private var selectedTab = 0
        @State private var showSprintView: Bool = false
        @State private var loadingSprintEvent: Bool = true
                
        var body: some View {
            Group {
                if let league = userData.selectedLeague {
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
                        } else {
                            BiddingViewPlaceholder()
                                .tabItem { Label("Lineup", systemImage: "flag.pattern.checkered") }
                                .tag(1)
                        }
                        
                        ExtraGameView()
                            .tabItem { Label("Extra", systemImage: "list.bullet") }
                            .tag(3)
                    }
                    .toolbar {
                        if userData.selectedLeague?.selectedEvent?.has_sprint == 1{
                            ToolbarItem(placement: .topBarTrailing){
                                ZStack(alignment: .topTrailing) {
                                    sprintMenu
                                    Text("")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            leagueMenu
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            EventToolbarButton(league: league, eventSheet: $eventSheet)
                        }
                    }
                    .sheet(isPresented: $eventSheet){
                        EventIndicatorMenu(league: league, userData: userData)
                    }
                    .onChange(of: selectedTab){
                        Task{
                            _ = await userData.selectedLeague!.selectedEvent!.load(leagueId: league.id, token: userData.token)
                        }
                    }
                } else {
                    // Fallback when no league is selected
                    ContentUnavailableView(
                        "No League Selected",
                        systemImage: "house.fill",
                        description: Text("Join or select a league from the menu.")
                    )
                }
            }
        }
        
        private var sprintMenu: some View {
            Button {
                showSprintView = true
            } label: {
                Image(systemName: "flag.fill")
            }
            //.applyGlassButtonStyleIfAvailable() //Apply .bottonStyle(.glass) on 26
            .sheet(isPresented: $showSprintView) {
                NavigationView {
                    if !loadingSprintEvent{
                        if let _ = league.selectedEvent!.sprint_event_object{
                            if league.selectedEvent!.sprint_event_object!.is_sprint == 1{ //Guard to make sure only sprints load
                                BiddingListView(
                                    league: league,
                                    event: league.selectedEvent!.sprint_event_object!,
                                    userData: userData
                                )
                            }
                            else{
                                Text("Error loading sprint data")
                            }
                        }
                        else{
                            Text("Error loading sprint data")
                        }
                    } else {
                        ProgressView()
                    }
                }.task{
                    // Only show loading if it hasn't yet been loaded
                    if let _ = league.selectedEvent!.sprint_event_object{
                        loadingSprintEvent = false
                    }
                    else{
                        loadingSprintEvent = true
                    }
                    
                    let success = await league.selectedEvent!.loadSprintEvent()
                    if success{
                        let success = await league.selectedEvent!.sprint_event_object!.load(leagueId: league.id, token: userData.token)
                        if !success{
                            print("Error loading sprint")
                        }
                        else{
                            loadingSprintEvent = false
                        }
                    }
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
                Image(systemName: "house.fill")
            }
            .applyGlassButtonStyleIfAvailable() //Apply .bottonStyle(.glass) on 26
        }
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
        @ObservedObject var userData: UserData

        var body: some View {
            List {
                ForEach(league.events.filter { $0.is_sprint == 0 }, id: \.id) { event in
                    Button{
                        league.selectedEvent = event
                        dismiss()
                        Task{
                            await event.load(leagueId: league.id, token: userData.token)
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

