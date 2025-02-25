import SwiftUI

struct FriendsSearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedTags: Set<Tag>
    @Binding var sortDirection: FriendsListViewModel.SortDirection
    @Binding var sortOption: FriendsListViewModel.SortOption
    @Binding var showingTagPicker: Bool
    @Binding var showingSortPicker: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.system(size: 16))
                TextField("Search friends", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Sort and Filter Controls
            HStack(spacing: 8) {
                // Sort Controls Group
                HStack(spacing: 0) {
                    // Direction Toggle Button
                    Button(action: { sortDirection.toggle() }) {
                        Image(systemName: sortDirection.systemImage)
                            .font(.system(size: 14))
                    }
                    .frame(width: 32, height: 32)
                    .background(sortDirection == .none ? Color(.systemGray6) : AppColors.accent)
                    .foregroundColor(sortDirection == .none ? AppColors.label : .white)
                    
                    // Sort Label
                    Text("Sort")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.label)
                        .padding(.horizontal, 8)
                    
                    Spacer(minLength: 0)
                    
                    // Sort Option Button
                    Button(action: { showingSortPicker = true }) {
                        HStack(spacing: 4) {
                            Text(sortOption.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.secondaryLabel)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        .frame(minWidth: 80, alignment: .leading)
                    }
                    .padding(.trailing, 8)
                }
                .padding(.leading, 0)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Filter Button
                Button(action: { showingTagPicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                        Text("Filter")
                            .font(.system(size: 14))
                        if !selectedTags.isEmpty {
                            Text("\(selectedTags.count)")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .foregroundColor(selectedTags.isEmpty ? AppColors.label : AppColors.accent)
            }
            .frame(height: 32)
            
            // Selected Tags
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            FilterTagView(tag: tag) {
                                selectedTags.remove(tag)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.systemBackground)
    }
} 