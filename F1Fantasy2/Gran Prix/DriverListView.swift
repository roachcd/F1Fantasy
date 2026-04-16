//
//  DriverListView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 4/9/26.
//

import SwiftUI

struct DriverListView: View{
    @ObservedObject var event: Event
    @ObservedObject var userData: UserData
    
    var body: some View{
        List{
            ForEach(
                event.drivers.filter { driver in
                    !event.user_lineup.contains(where: { $0.driver_id == driver.driver_id })
                },
                id: \.id
            ) { driver in
                HStack{
                    NavigationLink{
                        DriverView(driver: driver, event: event, userData: userData)
                    } label: {
                        DriverLabel(driver: driver)
                    }
                }
            }
        }.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button{
                    
                } label: {
                    Text("$\(event.budget)")
                }
            }
        }
    }
}

