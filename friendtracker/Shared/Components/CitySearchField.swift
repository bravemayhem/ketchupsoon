// UI for CitySearchField

import SwiftUI
import MapKit

struct CitySearchField: View {
    @Bindable var service: CitySearchService
    @State private var isShowingResults = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            TextField("City (Optional)", text: $service.searchInput)
                .focused($isFocused)
                .onChange(of: service.searchInput) { _, newValue in
                    service.updateSearchText(newValue)
                    isShowingResults = !newValue.isEmpty
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        isShowingResults = false
                    }
                }
            
            if isShowingResults && !service.searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 44) // Height of the TextField
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(service.searchResults, id: \.self) { result in
                                Button(action: {
                                    service.selectCity(result.title)
                                    isShowingResults = false
                                    isFocused = false
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .foregroundColor(AppColors.label)
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundColor(AppColors.secondaryLabel)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                }
                                
                                if result != service.searchResults.last {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(AppColors.systemBackground)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            Section("Friend Details") {
                CitySearchField(service: CitySearchService())
            }
        }
        .preferredColorScheme(.dark)
    }
}
