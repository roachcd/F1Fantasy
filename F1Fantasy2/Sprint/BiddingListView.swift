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
    
    var noBids: [Driver] {
        return event.drivers.filter { (driver: Driver) in
            driver.bid == nil
        }
    }
    
    var withBids: [Driver] {
        return event.drivers.filter { (driver: Driver) in
            driver.bid != nil
        }
    }
    
    var body: some View {
        List{
            if #unavailable(iOS 26) {
                HomeView.AccessoryView(selectedLeague: league, event: event)
            }
            Section(header: Text("No Bids Placed")){
                ForEach(noBids, id: \.id) { driver in
                    NavigationLink{
                        DriverBiddingView(event: event, userData: userData, driver: driver)
                    } label: {
                        DriverBiddingLabel(driver: driver)
                    }
                }
            }
            Section(header: Text("Bid Placed")) {
                ForEach(withBids, id: \.id) { driver in
                    NavigationLink{
                        DriverBiddingView(event: event, userData: userData, driver: driver)
                    } label: {
                        DriverBiddingLabel(driver: driver)
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
            GroupBox{
                Text("$\(driver.cost)")
            }
        }
    }
}

struct DriverBiddingLabel: View{
    @ObservedObject var driver: Driver
    
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
            GroupBox{
                if let amount = driver.bid?.amount {
                    Text("$\(amount)")
                }
                else {
                    Text("No Bid")
                }
            }
        }
    }
}
