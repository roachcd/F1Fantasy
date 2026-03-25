//
//  FeeInfo.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/24/26.
//

import SwiftUI

struct FeeInfo: View{
    var body: some View{
        VStack(spacing: 20){
            Label("Fees", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird").font(.title)
            Spacer()
            
            List{
                Section{
                    Label("Strategy and fair play", systemImage: "person.badge.shield.checkmark.fill").fontWeight(.bold)
                    Text("Fees help prevent last-second bids and reduce rapid back-and-forth bidding wars.")
                }
                Section{
                    Label("How they work", systemImage: "chart.bar.fill").fontWeight(.bold)
                    Text("Fees apply during the final 3 days of bidding and are calculated as a percentage of the total cost of the driver. Fees are non-refundable, even if you are outbid.")
                    Text("3 days before: 5%")
                    Text("2 days before: 10%")
                    Text("1 days before: 20%")
                    Text("Day of close: 40%")
                }
            }
            .scrollDisabled(true)
            Spacer()
            
        }.padding(20)
            .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    FeeInfo()
}
