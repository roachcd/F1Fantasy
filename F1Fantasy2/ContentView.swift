//
//  ContentView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: F1Fantasy2Document

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(F1Fantasy2Document()))
}
