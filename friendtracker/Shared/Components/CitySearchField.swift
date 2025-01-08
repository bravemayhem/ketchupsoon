import SwiftUI
import MapKit

struct CitySearchField: View {
    @Binding var searchText: String
    @Binding var selectedCity: String?
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchCompleterDelegate: SearchCompleterDelegate?
    @State private var isShowingResults = false
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("City (Optional)", text: $searchText)
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        selectedCity = nil
                        isShowingResults = false
                    } else {
                        searchCompleter.queryFragment = newValue
                        isShowingResults = true
                    }
                }
            
            if isShowingResults && !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(searchResults, id: \.self) { result in
                            Button(action: {
                                searchText = result.title
                                selectedCity = result.title
                                isShowingResults = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.title)
                                        .foregroundColor(AppColors.label)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundColor(AppColors.secondaryLabel)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(AppColors.secondarySystemBackground)
                .cornerRadius(8)
            }
        }
        .onAppear {
            searchCompleterDelegate = SearchCompleterDelegate(results: $searchResults)
            searchCompleter.delegate = searchCompleterDelegate
            searchCompleter.resultTypes = .address
            searchCompleter.addressFilter = MKAddressFilter(including: [.locality])
        }
    }
}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Binding var results: [MKLocalSearchCompletion]
    
    init(results: Binding<[MKLocalSearchCompletion]>) {
        _results = results
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { result in
            let subtitle = result.subtitle.lowercased()
            return subtitle.contains("city") || 
                   subtitle.contains("town") || 
                   subtitle.contains("municipality") ||
                   (!subtitle.contains("street") && !subtitle.contains("road") && !subtitle.contains("avenue"))
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("City search failed: \(error.localizedDescription)")
        results = []
    }
} 