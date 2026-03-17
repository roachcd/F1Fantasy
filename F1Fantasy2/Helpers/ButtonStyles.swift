//
//  ButtonStyles.swift
//  F13
//
//  Created by Chase Roach on 2/5/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyGlassButtonStyleIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}
