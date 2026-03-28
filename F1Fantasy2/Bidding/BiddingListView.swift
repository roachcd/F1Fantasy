import SwiftUI

/// The main view displaying a list of drivers associated with a selected league event, categorized by those with bids and without bids.
///
///   This view reads the selected league and event from the provided user data and lists drivers who have placed bids separately from those who have not. It displays a live indicator when the event is live, and automatically refreshes driver and user data periodically during live bidding.
///
/// - Parameters:
///   - league: The current league object observed for changes.
///   - event: The current event object observed for changes.
///   - userData: The user data object containing selections and user-specific information.
struct BiddingListView: View {
    @ObservedObject var league: League
    @ObservedObject var event: Event
    @ObservedObject var userData: UserData
    @State private var refreshTask: Task<Void, Never>?
    @State var didNotUpdate: Bool = true
    @State var showFeeInfo: Bool = false
    
    /// Returns all drivers sorted by total bids in descending order within the selected event.
    var sortedDrivers: [Driver] {
        if let event = league.selectedEvent{
            let sorted = event.drivers.sorted { (lhs: Driver, rhs: Driver) in
                lhs.total_bids > rhs.total_bids
            }
            return sorted
        }
        return []
    }
    
    /// Returns drivers who have placed no bids (total_bids equals zero).
    var noBids: [Driver] {
        return sortedDrivers.filter { (driver: Driver) in
            driver.total_bids == 0
        }
    }
    
    /// Returns drivers who have placed one or more bids (total_bids greater than zero).
    var withBids: [Driver] {
        return sortedDrivers.filter { (driver: Driver) in
            driver.total_bids > 0
        }
    }
    
    private var liveHeader: some View {
        HStack{
            Text("Currently Bidding")
            Spacer();
            if let league = userData.selectedLeague {
                if let event = league.selectedEvent {
                    if(event.status == 2){
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
            }
        }
    }
    
    var body: some View {
        if let league = userData.selectedLeague{
            if let event = league.selectedEvent{
                List{
                    if #unavailable(iOS 26) {
                        HomeView.AccessoryView(selectedLeague: league)
                    }
                    Section(header: liveHeader) {
                        ForEach(withBids, id: \.id) { driver in
                            NavigationLink{
                                DriverBiddingView(event: event, userData: userData, driver: driver)
                            } label: {
                                DriverLabel(driver: driver)
                            }
                        }
                    }
                    Section(header: Text("No Bids Placed")){
                        ForEach(noBids, id: \.id) { driver in
                            NavigationLink{
                                DriverBiddingView(event: event, userData: userData, driver: driver)
                            } label: {
                                DriverLabel(driver: driver)
                            }
                        }
                    }
                }
                .onAppear {
                    Task {
                        await event.load(leagueId: league.id)
                    }
                }
                .onAppear {
                    startAutoRefresh()
                }
                .onDisappear {
                    refreshTask?.cancel()
                }
                .onChange(of: event.id){
                    refreshTask?.cancel()
                    didNotUpdate = true
                    startAutoRefresh()
                    print("Event Changed")
                }
            }
        }
    }
    
    /// Starts the auto-refresh loop which repeatedly attempts to update driver and user data every 5 seconds when the event is live.
    /// If the update is successful within a 3-second timeout, the live indicator shows as updated, otherwise it shows a loading state.
    private func startAutoRefresh() {
        refreshTask?.cancel()

        if let league = userData.selectedLeague {
            if let event = league.selectedEvent {
                if event.status == 2{
                    refreshTask = Task {
                        while !Task.isCancelled {
                            do{
                                let success = try await withTimeout(.seconds(3)) {
                                    try await event.getDrivers(leagueId: league.id)
                                    await userData.updateThisUser()
                                    return true
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
                            try? await Task.sleep(for: .seconds(5))
                        }
                    }
                }
            }
        }
    }
}

struct DriverLabel: View{
    var driver: Driver
    
    var body: some View{
        HStack{
            Image("\(driver.name)")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(.secondary, lineWidth: 2)
                )
            Text("\(driver.name)")
            Spacer()
            if(driver.total_bids != -1){
                GroupBox{
                    Text("$\(driver.total_bids)")
                }
            }
        }
    }
}

