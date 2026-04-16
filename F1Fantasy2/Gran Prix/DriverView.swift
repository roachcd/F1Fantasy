//
//  DriverView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 4/9/26.
//

import SwiftUI

struct DriverView: View {
    var driver: Driver
    var event: Event
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView{
            Section{
                VStack(alignment: .center){
                    Image("\(driver.name)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(.secondary, lineWidth: 2)
                        )
                    Text(driver.name).font(.largeTitle).bold().padding(5)
                    HStack{
                        Text(driver.team).font(Font.title2).bold()
                        Text("#\(driver.car_number)").font(Font.title2)
                    }
                }
            }.padding(25)
        }
        .toolbar{
            if event.status == 2 && event.is_sprint == 0{
                ToolbarItem(placement: .topBarTrailing){
                    if(event.user_lineup.contains(driver)){
                        Button {
                            Task{
                                if let selectedLeague = userData.selectedLeague{
                                    do{
                                        try await event.removeDriver(driver: driver, leagueId: selectedLeague.id, token: userData.token)
                                        dismiss()
                                    }
                                    catch{
                                        print(error)
                                    }
                                }
                            }
                        } label: {
                            Text("Remove Driver")
                        }
                    }
                    else if event.budget >= driver.cost{
                        Button {
                            Task{
                                if let selectedLeague = userData.selectedLeague{
                                    do{
                                        try await event.addDriver(driver: driver, leagueId: selectedLeague.id, token: userData.token)
                                        dismiss()
                                    }
                                    catch{
                                        print(error)
                                    }
                                }
                            }
                        } label: {
                            Text("Add Driver")
                        }
                    }
                    else{
                        Button {

                        } label: {
                            Text("Not enough money")
                        }
                    }
                }
            }
        }
    }
}
