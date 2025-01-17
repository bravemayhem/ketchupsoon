import SwiftUI

extension View {
    func datePickerSheet(
        isPresented: Binding<Bool>,
        date: Binding<Date>,
        onSave: @escaping (Date) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
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