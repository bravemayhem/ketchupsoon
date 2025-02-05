import SwiftUI

struct ProfileImage: View {
    let friend: Friend
    let showBorder: Bool
    
    init(friend: Friend, showBorder: Bool = true) {
        self.friend = friend
        self.showBorder = showBorder
    }
    
    var body: some View {
        if let photoData = friend.photoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .if(showBorder) { view in
                    view.overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    )
                }
        } else {
            InitialsAvatar(name: friend.name, showBorder: showBorder)
        }
    }
}

struct InitialsAvatar: View {
    let name: String
    let showBorder: Bool
    
    init(name: String, showBorder: Bool = true) {
        self.name = name
        self.showBorder = showBorder
    }
    
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarColor(for: name))
            
            Text(initials)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 48, height: 48)
        .if(showBorder) { view in
            view.overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
        }
    }
}

struct LargeProfileImage: View {
    let friend: Friend
    let showBorder: Bool
    
    init(friend: Friend, showBorder: Bool = true) {
        self.friend = friend
        self.showBorder = showBorder
    }
    
    var body: some View {
        if let photoData = friend.photoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .if(showBorder) { view in
                    view.overlay(
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
        } else {
            LargeInitialsAvatar(name: friend.name, showBorder: showBorder)
        }
    }
}

struct LargeInitialsAvatar: View {
    let name: String
    let showBorder: Bool
    
    init(name: String, showBorder: Bool = true) {
        self.name = name
        self.showBorder = showBorder
    }
    
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarColor(for: name))
            
            Text(initials)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 96, height: 96)
        .if(showBorder) { view in
            view.overlay(
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Regular avatars
            VStack(spacing: 24) {
                Text("Regular Size")
                    .font(.headline)
                    .foregroundColor(AppColors.label)
                
                HStack(spacing: 24) {
                    ProfileImage(friend: Friend(
                        name: "John Doe",
                        location: "Local",
                        needsToConnectFlag: true
                    ))
                    
                    ProfileImage(friend: Friend(
                        name: "Alice Smith",
                        location: "Local",
                        needsToConnectFlag: false
                    ))
                    ProfileImage(friend: Friend(
                        name: "Bob Wilson",
                        location: "Local",
                        needsToConnectFlag: false
                    ))
                }
            }
            
            // Large avatars
            VStack(spacing: 24) {
                Text("Large Size")
                    .font(.headline)
                    .foregroundColor(AppColors.label)
                
                HStack(spacing: 24) {
                    LargeProfileImage(friend: Friend(
                        name: "Emma Davis",
                        location: "Local",
                        needsToConnectFlag: false
                    ))
                    
                    LargeProfileImage(friend: Friend(
                        name: "Mike Brown",
                        location: "Local",
                        needsToConnectFlag: false
                    ))
                }
            }
        }
        .padding(32)
        .background(
            AppColors.glassMorphism()
                .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .padding(24)
    }
    .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}

