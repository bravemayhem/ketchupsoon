import SwiftUI

struct SortPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sortOption: FriendsListViewModel.SortOption
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(FriendsListViewModel.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(AppColors.label)
                            Spacer()
                            if option == sortOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.systemBackground)
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
} 