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
}

// MARK: - Modifier Preview Code
struct SheetModifierPreview: View {
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            // Date Picker section
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
        }
        .padding()
        .datePickerSheet(
            isPresented: $showDatePicker,
            date: $selectedDate
        ) { newDate in
            selectedDate = newDate
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
