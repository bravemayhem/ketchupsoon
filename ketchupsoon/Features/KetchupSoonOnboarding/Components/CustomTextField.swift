import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("SpaceGrotesk-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
                    .frame(height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                }
                
                TextField("", text: $text)
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .accentColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                    .accessibilityLabel(title)
            }
        }
    }
}

struct CustomTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("SpaceGrotesk-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(height: 100)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .accentColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                    .accessibilityLabel(title)
            }
        }
    }
} 