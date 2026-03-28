import SwiftUI

/// A view that displays a ranked list of managers within the selected league
///
/// - Parameters:
///   - userData: An observed object providing the selected league and related data.
struct ManagersList: View{
    @ObservedObject var userData: UserData
    
    /// Returns the list of managers sorted by points in descending order for the selected league.
    ///
    /// If no league is selected, returns an empty array.
    var sortedManagers: [Manager] {
        userData.selectedLeague?.managers.sorted { $0.points > $1.points } ?? []
    }
    
    /// Returns a color corresponding to the manager's rank index.
    ///
    /// Color mapping:
    /// - 0: gold (yellow)
    /// - 1: silver (gray)
    /// - 2: bronze (brown)
    /// - default: system grouped background color
    ///
    /// - Parameter index: The rank index of the manager.
    /// - Returns: A `Color` representing the medal or default background.
    func colorForIndex(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow        // gold
        case 1: return .gray          // silver
        case 2: return .brown         // bronze
        default: return Color(.systemGroupedBackground)
        }
    }
    
    var body: some View {
        List{
            if let league = userData.selectedLeague {
                if let event = league.selectedEvent {
                    ForEach(Array(sortedManagers.enumerated()), id: \.element.id) { index, manager in
                        NavigationLink{
                            ManagerView(manager: manager, userData: userData)
                        } label: {
                            HStack{
                                Image(systemName: "\(index + 1).circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                    .foregroundStyle(.primary, colorForIndex(index))
                                    .overlay(
                                        Circle().stroke(.secondary, lineWidth: 2)
                                    )
                                Text(manager.username)
                                Spacer()
                                GroupBox{
                                    Text("\(manager.points) points")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

