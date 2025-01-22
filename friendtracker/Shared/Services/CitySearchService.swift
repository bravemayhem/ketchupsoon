// Logic layer for the city search. Handles city search state and filtering logic.
//  CitySearchService.swift
//  friendtracker
//
//  Created by Amineh Beltran on 1/21/25.
//

import SwiftUI
import MapKit

@Observable class CitySearchService: NSObject, MKLocalSearchCompleterDelegate {
    var searchInput = ""
    var selectedCity: String?
    var searchResults: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        searchCompleter.addressFilter = MKAddressFilter(including: [.locality])
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results.filter { result in
            let subtitle = result.subtitle.lowercased()
            return subtitle.contains("city") || 
                   subtitle.contains("town") || 
                   subtitle.contains("municipality") ||
                   (!subtitle.contains("street") && !subtitle.contains("road") && !subtitle.contains("avenue"))
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("City search failed: \(error.localizedDescription)")
        searchResults = []
    }
    
    func updateSearchText(_ text: String) {
        searchInput = text
        if text.isEmpty {
            selectedCity = nil
            searchResults = []
        } else {
            searchCompleter.queryFragment = text
        }
    }
    
    func selectCity(_ city: String) {
        selectedCity = city
        searchInput = city
        searchResults = []
    }
}
