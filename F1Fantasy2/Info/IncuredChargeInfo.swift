//
//  IncuredCharge.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/24/26.
//

import SwiftUI

/// A view presenting information about Incured Charges.
struct IncuredChargeInfo: View{
    var body: some View{
        VStack(spacing: 20){
            Label("Incurred Charges", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird").font(.title)
            Spacer()
            
            List{
                Section{
                    Label("When Bidding", systemImage: "person.badge.shield.checkmark.fill").fontWeight(.bold)
                    Text("When you place a bid, you pay your bid amount plus all incremental increases leading up to it.")
                }
                Section{
                    Label("When you're outbid", systemImage: "chart.bar.fill").fontWeight(.bold)
                    Text("If you’re outbid, both your bid and any incurred charges are automatically refunded.")
                }
            }
            .scrollDisabled(true)
            Spacer()
            
        }.padding(20)
            .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    IncuredChargeInfo()
}
