import SwiftUI

/// A reusable badge component for showing status indicators (online, away, busy, etc)
struct StatusBadge: View {
    // MARK: - Properties
    var status: Status = .online
    var size: BadgeSize = .small
    var customColor: Color? = nil
    var showBorder: Bool = true
    var customOffset: CGPoint? = nil
    
    // MARK: - Status Types
    enum Status {
        case online
        case offline
        case away
        case busy
        case custom(Color)
        
        var color: Color {
            switch self {
            case .online:
                return Color.green
            case .offline:
                return Color.gray
            case .away:
                return Color.yellow
            case .busy:
                return Color.red
            case .custom(let color):
                return color
            }
        }
    }
    
    // MARK: - Size Options
    enum BadgeSize {
        case tiny     // 8pt - For very discreet indicators
        case small    // 12pt - Default size
        case medium   // 16pt - More noticeable
        case large    // 20pt - Very prominent
        
        var diameter: CGFloat {
            switch self {
            case .tiny: return 8
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .tiny: return 1
            case .small: return 1.5
            case .medium: return 2
            case .large: return 2.5
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        Circle()
            .fill(customColor ?? status.color)
            .frame(width: size.diameter, height: size.diameter)
            .shadow(color: (customColor ?? status.color).opacity(0.6), radius: 3, x: 0, y: 0)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: showBorder ? size.borderWidth : 0)
            )
            .offset(x: customOffset?.x ?? 0, y: customOffset?.y ?? 0)
    }
}

// MARK: - View Extension
extension View {
    /// Adds a status badge to a view (typically an avatar)
    func withStatus(_ status: StatusBadge.Status, size: StatusBadge.BadgeSize = .small, alignment: Alignment = .bottomTrailing, offset: CGPoint? = nil) -> some View {
        self.overlay(
            StatusBadge(status: status, size: size, customOffset: offset),
            alignment: alignment
        )
    }
}

// MARK: - Preview
#Preview("Status Badges") {
    VStack(spacing: 30) {
        // Different statuses
        HStack(spacing: 20) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online)
                .overlay(Text("Online").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.offline)
                .overlay(Text("Offline").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.away)
                .overlay(Text("Away").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.busy)
                .overlay(Text("Busy").font(.caption).foregroundColor(.white), alignment: .center)
        }
        
        // Different sizes
        HStack(spacing: 20) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, size: .tiny)
                .overlay(Text("Tiny").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, size: .small)
                .overlay(Text("Small").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, size: .medium)
                .overlay(Text("Medium").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, size: .large)
                .overlay(Text("Large").font(.caption).foregroundColor(.white), alignment: .center)
        }
        
        // Custom placement
        HStack(spacing: 20) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, alignment: .topTrailing)
                .overlay(Text("Top Right").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.online, alignment: .topLeading)
                .overlay(Text("Top Left").font(.caption).foregroundColor(.white), alignment: .center)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .withStatus(.custom(AppColors.purple), size: .medium)
                .overlay(Text("Custom").font(.caption).foregroundColor(.white), alignment: .center)
        }
    }
    .padding()
    .background(Color.black)
} 