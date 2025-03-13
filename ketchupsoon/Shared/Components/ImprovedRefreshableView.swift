import SwiftUI

/// An improved refreshable view component with built-in debounce protection
/// to prevent multiple rapid refresh requests during pull gestures
struct ImprovedRefreshableView<Content: View>: View {
    // State
    @Binding var isRefreshing: Bool
    @State private var lastRefreshTime: Date? = nil
    @State private var isGestureActive = false
    
    // Configuration
    let debounceInterval: TimeInterval
    let refreshThreshold: CGFloat
    let action: () async -> Void
    let content: () -> Content
    
    init(
        isRefreshing: Binding<Bool>,
        debounceInterval: TimeInterval = 1.0,
        refreshThreshold: CGFloat = 50,
        action: @escaping () async -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.debounceInterval = debounceInterval
        self.refreshThreshold = refreshThreshold
        self.action = action
        self.content = content
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            content()
                .zIndex(0)
            
            // Refresh indicator
            GeometryReader { geometry in
                if isRefreshing {
                    HStack {
                        Spacer()
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Refreshing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                    .zIndex(1)
                }
                
                // Invisible spacer that triggers refresh
                Color.clear
                    .onChange(of: geometry.frame(in: .global).minY) { oldValue, newValue in
                        let shouldRefresh = newValue > refreshThreshold && !isGestureActive
                        
                        if shouldRefresh {
                            // Prevent multiple triggers in quick succession
                            isGestureActive = true
                            
                            // Check debounce time
                            let now = Date()
                            if let lastRefresh = lastRefreshTime, 
                               now.timeIntervalSince(lastRefresh) < debounceInterval {
                                print("🔄 ImprovedRefreshableView: Skipping refresh - too soon")
                                // Reset after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isGestureActive = false
                                }
                                return
                            }
                            
                            // Perform refresh
                            isRefreshing = true
                            lastRefreshTime = now
                            
                            // Execute refresh action
                            Task {
                                print("🔄 ImprovedRefreshableView: Starting refresh")
                                await action()
                                
                                // Reset gesture state after completion
                                await MainActor.run {
                                    isGestureActive = false
                                }
                                print("🔄 ImprovedRefreshableView: Completed refresh")
                            }
                        }
                    }
            }
            .frame(height: 0) // Zero height, but still detects scroll position
        }
    }
}

/// Simplified version that can be used as a drop-in replacement for the original RefreshableView
struct SimpleRefreshableView: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            // Using ImprovedRefreshableView internally
            if geometry.frame(in: .global).minY > 50 && !isRefreshing {
                Spacer()
                    .onAppear {
                        // Check if we're already refreshing to avoid multiple triggers
                        guard !isRefreshing else { return }
                        
                        isRefreshing = true
                        Task {
                            print("🔄 SimpleRefreshableView: Starting refresh")
                            await action()
                            print("🔄 SimpleRefreshableView: Completed refresh")
                        }
                    }
            } else if isRefreshing {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                }
                .frame(height: 50)
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ImprovedRefreshableView(
                isRefreshing: .constant(false),
                action: {
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            ) {
                Text("Pull to refresh")
                    .font(.title)
                    .padding()
            }
            
            ForEach(1...20, id: \.self) { num in
                Text("Item \(num)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
