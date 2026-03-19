//
//  EventView.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import SwiftUI
internal import Combine

final class EventDraft: ObservableObject {
    @Published var name: String
    @Published var status: Int
    @Published var drivers: [Driver] = []
    
    init(name: String, status: Int, drivers: [Driver]) {
        self.name = name
        self.status = status
        self.drivers = drivers
    }
}

struct EventView: View{
    var event: Event
    @StateObject private var draft: EventDraft
    @State var showDrivers: Bool = false
    @State var submitting: Bool = false
    
    init(event: Event) {
        self.event = event
        _draft = StateObject(wrappedValue: EventDraft(name: event.name, status: event.status, drivers: event.drivers))
    }
    
    var body: some View{
        List{
            HStack{
                Text("Name")
                Spacer()
                TextField("Name", text: $draft.name)
                    .frame(maxWidth: 180)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack{
                Text("Status")
                Spacer()
                Menu{
                    Button{
                        draft.status = 2
                    } label: {
                        Text("Unlocked (Editing)")
                    }
                    Button{
                        draft.status = 1
                    } label: {
                        Text("Locked (No editing)")
                    }
                    Button{
                        draft.status = 3
                    } label: {
                        Text("Finished (No editing)")
                    }
                } label: {
                    if draft.status == 2{
                        Text("Unlocked")
                    }
                    else if draft.status == 1{
                        Text("Locked")
                    }
                    else if draft.status == 3{
                        Text("Finished")
                    }
                    else{
                        Text("Error")
                    }
                }
            }
            
            HStack{
                Text("Drivers")
                Spacer()
                Button{
                    showDrivers = true;
                } label: {
                    Text("Edit")
                }
            }
            .sheet(isPresented: $showDrivers){
                DriverListView(drivers: $draft.drivers).frame(width: 600, height: 700)
            }

        }
        .toolbar{
            Button{
                Task{
                    submitting = true;
                    let success = await appData.updateEvent(event: event!);
                    if success{
                        submitting = false;
                        eventCopy = event;
                    }
                }
            } label: {
                if(submitting){
                    ProgressView()
                }
                else{
                    Text("Apply")
                }
            }
        }
        .onChange(of: event) { newValue in
            draft.name = newValue.name
            draft.status = newValue.status
            draft.drivers = newValue.drivers
        }
        .onAppear {
            draft.name = event.name
            draft.status = event.status
            draft.drivers = event.drivers
        }
    }
}

