// Logic layer for the city search. Handles city search state and filtering logic.
//  CitySearchService.swift
//  friendtracker
//
//  Created by Amineh Beltran on 1/21/25.
//

import SwiftUI

@Observable class CitySearchService {
    var searchInput = ""
    var selectedCity: String?
    
    private let cities = [
        "San Francisco, CA",
        "New York, NY",
        // ... other cities
    ]
    
    var filteredCities: [String] {
        if searchInput.isEmpty {
            return cities
        }
        return cities.filter { $0.lowercased().contains(searchInput.lowercased()) }
    }
    
    func selectCity(_ city: String) {
        selectedCity = city
        searchInput = city
    }
}
