import SwiftUI

struct StatsView: View {
    let hangoutsThisMonth: Int
    let moodRating: Int // 1-5 scale
    
    var moodEmoji: String {
        switch moodRating {
        case 1: return "😔"
        case 2: return "😕"
        case 3: return "😊"
        case 4: return "😃"
        case 5: return "🤗"
        default: return "😊"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Inspiration Quote
            Text("Remember: Strong relationships are the #1 predictor of happiness!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Stats Cards
            HStack(spacing: 12) {
                // Hangouts Card
                VStack {
                    Text("\(hangoutsThisMonth)")
                        .font(.title)
                        .bold()
                    Text("Hangouts\nthis month")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(NeoBrutalistBackground())
                
                // Mood Card
                VStack {
                    Text(moodEmoji)
                        .font(.title)
                    Text("Current\nmood")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(NeoBrutalistBackground())
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
} 