//
//  ContentView.swift
//  AliceMobile
//
//  Created by 方文栋 on 2026/6/6.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        CompanionHomeView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
