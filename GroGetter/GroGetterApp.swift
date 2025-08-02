//
//  GroGetterApp.swift
//  GroGetter
//
//  Created by Jared Mallas on 8/2/25.
//

import SwiftUI

@main
struct GroGetterApp: App {
    @StateObject private var store = GroceryStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light) // Force light mode for consistency
                .onAppear {
                    // Set default appearance
                    UITableView.appearance().backgroundColor = .clear
                    UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.label]
                }
        }
    }
}
