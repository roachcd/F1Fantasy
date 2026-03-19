//
//  AdminApp.swift
//  Admin
//
//  Created by Chase Roach on 3/19/26.
//

import SwiftUI

@main
struct AdminApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(AppData())
        }
    }
}
