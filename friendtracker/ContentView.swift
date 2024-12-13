//
//  ContentView.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color(hex: "#F2F7F5"))
        navBarAppearance.shadowColor = .clear
        
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#2F3B35")),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#2F3B35")),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color(hex: "#F2F7F5"))
        
        // Update tab bar item colors
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#6B7C73"))
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#6B7C73"))
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#4CAF90"))
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#4CAF90"))
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
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
        .tint(Theme.primary)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: isDarkMode) { oldValue, newValue in
            themeManager.toggleTheme(isDark: newValue)
        }
        .onAppear {
            themeManager.toggleTheme(isDark: isDarkMode)
        }
    }
}

#Preview {
    ContentView()
}
