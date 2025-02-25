//
//  CitySelectionSection.swift
//  ketchupsoon
//
//  Created by Amineh Beltran on 2/5/25.
//
import SwiftUI
import SwiftData

// MARK: - City Selection Section
struct FriendCitySection: View {
    @Bindable var cityService: CitySearchService
    
    var body: some View {
        Section("Location") {
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}
