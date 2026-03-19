//
//  ExtraGameView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct ExtraGameView: View {
    var body: some View {
        List{
            Section(header: Text("Games")){
                NavigationLink{
                    
                } label: {
                    Text("Pole")
                }
                NavigationLink{
                    
                } label: {
                    Text("Last Place")
                }
            }
            Section(header: Text("Tools")){
                NavigationLink{
                    
                } label: {
                    Text("Convert points to cash")
                }
            }
        }
    }
}
