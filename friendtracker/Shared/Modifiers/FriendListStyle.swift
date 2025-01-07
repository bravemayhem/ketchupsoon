// FriendListStyle: Handles the style of the friend list
// This is a modifier that allows us to style the friend list 
// List Style - Handles APPEARANCE only

import SwiftUI

struct FriendListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.systemBackground)
            .environment(\.defaultMinListRowHeight, 0)
            .environment(\.defaultMinListHeaderHeight, 0)
    }
}

struct FriendCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func friendListStyle() -> some View {
        modifier(FriendListStyle())
    }
    
    func friendCardStyle() -> some View {
        modifier(FriendCardStyle())
    }
} 