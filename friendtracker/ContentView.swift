//
//  ContentView.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(themeManager.currentTheme.background)
        navBarAppearance.shadowColor = .clear
        
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(themeManager.currentTheme.primaryText),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(themeManager.currentTheme.primaryText),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
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
        .accentColor(themeManager.currentTheme.primary)
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
