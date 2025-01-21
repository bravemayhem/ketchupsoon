//
//  FriendFormBase.swift
//  friendtracker
//
//  Created by Amineh Beltran on 1/20/25.
//
import SwiftUI
import SwiftData

// MARK: - Form Configuration Protocol
protocol FriendFormConfiguration {
    var showsName: Bool { get }
    var showsContactInfo: Bool { get }
    var showsActions: Bool { get }
    var showsHangouts: Bool { get }
    var showsCatchUpFrequency: Bool { get }
    var showsLastSeen: Bool { get }
    var showsLocation: Bool { get }
    var showsTags: Bool { get }
    var showsWishlist: Bool { get }
}

// MARK: - Form Configuration Types
struct OnboardingConfiguration: FriendFormConfiguration {
    let showsName = true
    let showsContactInfo = true
    let showsActions = false
    let showsHangouts = false
    let showsCatchUpFrequency = true
    let showsLastSeen = true
    let showsLocation = true
    let showsTags = true
    let showsWishlist = true
}

struct ExistingConfiguration: FriendFormConfiguration {
    let showsName = true
    let showsContactInfo = true
    let showsActions = true
    let showsHangouts = true
    let showsCatchUpFrequency = true
    let showsLastSeen = true
    let showsLocation = true
    let showsTags = true
    let showsWishlist = true
}

// MARK: - Form Configuration Factory
enum FormConfiguration {
    static let onboarding = OnboardingConfiguration()
    static let existing = ExistingConfiguration()
}

// MARK: - Base Friend Form
struct BaseFriendForm<Content: View>: View {
    let configuration: FriendFormConfiguration
    let content: (FriendFormConfiguration) -> Content
    
    init(configuration: FriendFormConfiguration, @ViewBuilder content: @escaping (FriendFormConfiguration) -> Content) {
        self.configuration = configuration
        self.content = content
    }
    
    var body: some View {
        List {
            content(configuration)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)
        .environment(\.defaultMinListHeaderHeight, 0)
        .background(AppColors.systemBackground)
    }
}
