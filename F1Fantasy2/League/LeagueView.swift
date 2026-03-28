
import SwiftUI

/// `LeagueView` is the entry point for the league-related user interface.
/// 
/// Composes `ManagersList` using the shared `UserData` object to display the list of managers.
/// 
/// - Parameter userData: The shared user data object used to provide data to the view.
struct LeagueView: View {
    @ObservedObject var userData: UserData
    var body: some View {
        ManagersList(userData: userData)
    }
}
