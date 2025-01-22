// UI for CitySearchField

import SwiftUI

struct CitySearchField: View {
    @Bindable var service: CitySearchService
    
    var body: some View {
        VStack {
            TextField("Search cities...", text: $service.searchInput)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            List(service.filteredCities, id: \.self) { city in
                Button(action: {
                    service.selectCity(city)
                }) {
                    HStack {
                        Text(city)
                        Spacer()
                        if city == service.selectedCity {
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
            service: CitySearchService()
        )
    }
}
