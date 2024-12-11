//
//  ContentView.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    init() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Theme.background)
        navBarAppearance.shadowColor = .clear // Remove the separator line
        
        // Large title text attributes
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.primaryText),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Standard title text attributes
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.primaryText),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Apply the appearance globally
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    var body: some View {
        TabView {
            FriendsListView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            SchedulerView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .accentColor(Theme.primary)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: isDarkMode) {
            Theme.current = isDarkMode ? .dark : .light
        }
        .onAppear {
            Theme.current = isDarkMode ? .dark : .light
            
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor(Theme.secondaryBackground)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
