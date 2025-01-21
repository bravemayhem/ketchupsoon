import SwiftUI

extension View {
    // MARK: - Date Picker Sheet Modifier
    func datePickerSheet(
        isPresented: Binding<Bool>,
        date: Binding<Date>,
        onSave: @escaping (Date) -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NavigationStack {
                Form {
                    DatePicker(
                        "Select Date",
                        selection: date,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppColors.accent)
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.systemBackground)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented.wrappedValue = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(date.wrappedValue)
                            isPresented.wrappedValue = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    func cityPickerSheet(
        isPresented: Binding<Bool>,
        searchText: Binding<String>,
        selectedCity: Binding<String?>,
        onSave: @escaping () -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            NavigationStack {
                CitySearchField(
                    searchText: searchText,
                    selectedCity: selectedCity
                )
                .navigationTitle("Select City")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented.wrappedValue = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave()
                            isPresented.wrappedValue = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
} 

struct SheetModifierPreview: View {
    @State private var showDatePicker = false
    @State private var showCityPicker = false
    @State private var selectedDate = Date()
    @State private var searchText = ""
    @State private var selectedCity: String?
    
    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Date Picker Sheet")
                    .font(AppTheme.headlineFont)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text("Selected Date:")
                        .font(AppTheme.bodyFont)
                    Text(selectedDate.formatted(date: .long, time: .omitted))
                        .cardSecondaryText()
                }
                .padding()
                .cardBackground()
                
                Button("Show Date Picker") {
                    showDatePicker = true
                }
                .cardButton(style: .primary)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("City Picker Sheet")
                    .font(AppTheme.headlineFont)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text("Selected City:")
                        .font(AppTheme.bodyFont)
                    Text(selectedCity ?? "No city selected")
                        .cardSecondaryText()
                }
                .padding()
                .cardBackground()
                
                Button("Show City Picker") {
                    showCityPicker = true
                }
                .cardButton(style: .primary)
            }
        }
        .padding()
        .datePickerSheet(
            isPresented: $showDatePicker,
            date: $selectedDate
        ) { newDate in
            selectedDate = newDate
        }
        .cityPickerSheet(
            isPresented: $showCityPicker,
            searchText: $searchText,
            selectedCity: $selectedCity
        ) {
            // Handle city save
        }
    }
}

#Preview("Sheet Modifiers") {
    NavigationStack {
        SheetModifierPreview()
            .navigationTitle("Sheet Modifiers")
    }
    .background(AppColors.systemBackground)
} 
