import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Profile")
                    .font(.title)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
} 