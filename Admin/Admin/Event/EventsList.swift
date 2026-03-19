//
//  EventsList.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import SwiftUI

struct EventsList: View{
    @State var loading: Bool = true
    @ObservedObject var appData: AppData
    
    var body: some View{
        if loading{
            ProgressView()
                .task {
                    var success = false
                    success = await appData.getAllDrivers()
                    success = await appData.getEvents()
                    if success{
                        loading = false
                    }
                }
        }else{
            List(appData.events){ event in
                NavigationLink(destination: EventView(event: event)){
                    Text(event.name)
                }
            }
        }
    }
}
