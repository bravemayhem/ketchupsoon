import SwiftUI

struct CitySearchField: View {
    @Binding var searchText: String
    @Binding var selectedCity: String?
    
    // Example cities for the preview
    private let cities = [
        "San Francisco, CA",
        "New York, NY",
        "Los Angeles, CA",
        "Chicago, IL",
        "Seattle, WA",
        "Boston, MA",
        "Austin, TX",
        "Portland, OR"
    ]
    
    var filteredCities: [String] {
        if searchText.isEmpty {
            return cities
        }
        return cities.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        VStack {
            TextField("Search cities...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            List(filteredCities, id: \.self) { city in
                Button(action: {
                    selectedCity = city
                    searchText = city
                }) {
                    HStack {
                        Text(city)
                        Spacer()
                        if city == selectedCity {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CitySearchField(
            searchText: .constant(""),
            selectedCity: .constant(nil)
        )
    }
} 