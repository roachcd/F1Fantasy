//
//  ManagersList.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/16/26.
//

import SwiftUI

struct ManagersList: View{
    @ObservedObject var userData: UserData
    
    var sortedManagers: [Manager] {
        userData.selectedLeague?.managers.sorted { $0.points > $1.points } ?? []
    }
    
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
            ForEach(Array(sortedManagers.enumerated()), id: \.element.id) { index, manager in
                NavigationLink{
                    ManagerView(manager: manager, league: userData.selectedLeague!, event: userData.selectedLeague!.selectedEvent!, userData: userData)
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
