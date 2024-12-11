import SwiftUI

struct GoalsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Track Your Goals")
                    .font(.title)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Goals")
        }
    }
} 