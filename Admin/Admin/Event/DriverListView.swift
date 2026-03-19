//
//  DriverListView.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import SwiftUI

struct DriverListView: View {
    @Binding var drivers: [Driver]
    @State private var sortedDrivers: [Driver] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack{
            Button{
                drivers = sortedDrivers
                dismiss()
            } label: {
                Text("Save")
            }
            List {
                ForEach(Array(sortedDrivers.enumerated()), id: \.element.id) { index, driver in
                    HStack {
                        Text("\(index)")
                        Text(driver.name)
                        Spacer()
                        
                    }
                }.onMove(perform: move)
            }
            .onAppear {
                sortedDrivers = drivers.sorted { $0.position < $1.position }
            }
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        sortedDrivers.move(fromOffsets: source, toOffset: destination)
        // Recompute positions after move
        for i in sortedDrivers.indices {
            sortedDrivers[i].position = i + 1
        }
    }
}
