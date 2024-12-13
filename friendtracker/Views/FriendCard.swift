import SwiftUI

struct FriendCard: View {
    let friend: Friend
    @State private var showingDetail = false
    
    var body: some View {
        CardButton(
            friend: friend,
            showingDetail: $showingDetail
        )
    }
}

// Simplified button component
private struct CardButton: View {
    let friend: Friend
    @Binding var showingDetail: Bool
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            CardContent(friend: friend)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            FriendDetailView(friend: friend)
        }
    }
}

// Simplified content component
private struct CardContent: View {
    let friend: Friend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderRow(friend: friend)
            InfoRows(friend: friend)
        }
        .padding(20)
        .background(NeoBrutalistBackground())
        .padding(.horizontal)
    }
}

// Header row component
private struct HeaderRow: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            Text(friend.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.primaryText)
            Spacer()
            if friend.isOverdue {
                OverdueTag()
            }
        }
    }
}

// Info rows component
private struct InfoRows: View {
    let friend: Friend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(friend.frequency)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.secondaryText)
            
            Text("\(friend.lastHangoutWeeks) weeks since last hangout")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Theme.secondaryText)
        }
    }
}

// Overdue tag component
private struct OverdueTag: View {
    var body: some View {
        Text("overdue")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color(hex: "#FF6B6B"))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
    }
}

#Preview {
    FriendCard(friend: Friend(
        id: UUID(),
        name: "John Doe",
        frequency: "Weekly check-in",
        lastHangoutWeeks: 2,
        phoneNumber: "+1234567890",
        isInnerCircle: true,
        isLocal: true
    ))
} 