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
                .onAppear {
                    // Set default appearance
                    UITableView.appearance().backgroundColor = .clear
                    
                    // Update navigation bar appearance to work with both light and dark mode
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithDefaultBackground()
                    UINavigationBar.appearance().standardAppearance = appearance
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
                    UINavigationBar.appearance().compactAppearance = appearance
                    
                    // Set title color that works in both light and dark mode
                    UINavigationBar.appearance().largeTitleTextAttributes = [
                        .foregroundColor: UIColor.label
                    ]
                }
        }
    }
}
