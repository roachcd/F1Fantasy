//
//  ButtonStyles.swift
//  F13
//
//  Created by Chase Roach on 2/5/26.
//

import SwiftUI

/// Applys liquid glass to buttons if iOS 26 is available
///
/// Usage:
/// ```
///  Menu{
///
///  } label : {
///
///  }.applyGlassButtonStyleIfAvailable

extension View {
    @ViewBuilder
    func applyGlassButtonStyleIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}
