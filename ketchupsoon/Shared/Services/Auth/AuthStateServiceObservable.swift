import SwiftUI
import Combine

/// A property wrapper for SwiftUI integration with AuthStateService
///
/// This wrapper makes it easier to use AuthStateService in SwiftUI views by providing
/// a clean interface to the current auth state and the service itself.
///
/// Example usage:
/// ```
/// struct MyView: View {
///     @AuthStateServiceObservable var authState
///
///     var body: some View {
///         if authState.isAuthenticated {
///             Text("Welcome, user \(authState.userID ?? "")")
///         } else {
///             Text("Please sign in")
///         }
///     }
/// }
/// ```
@propertyWrapper
struct AuthStateServiceObservable: DynamicProperty {
    @ObservedObject private var authService = AuthStateService.shared
    
    /// The current authentication state
    var wrappedValue: AuthState {
        authService.currentState
    }
    
    /// The AuthStateService itself, useful for calling methods like refreshState()
    var projectedValue: AuthStateService {
        authService
    }
}

/// A View extension to simplify subscribing to auth state changes
extension View {
    /// Subscribe the provided subscriber to auth state changes
    /// - Parameter subscriber: The object implementing AuthStateSubscriber that will receive auth state updates
    /// - Returns: The modified view
    func onAuthStateChange(_ subscriber: AuthStateSubscriber) -> some View {
        self.onAppear {
            AuthStateService.shared.subscribe(subscriber)
        }
        .onDisappear {
            AuthStateService.shared.unsubscribe(subscriber)
        }
    }
    
    /// Subscribe to auth state changes with a closure
    /// - Parameter handler: Closure that will be called when auth state changes
    /// - Returns: The modified view
    func onAuthStateChange(_ handler: @escaping (AuthState, AuthState?) -> Void) -> some View {
        self.modifier(AuthStateChangeModifier(onStateChange: handler))
    }
}

/// Internal modifier for handling auth state changes with a closure
private struct AuthStateChangeModifier: ViewModifier {
    let onStateChange: (AuthState, AuthState?) -> Void
    
    // Use State to hold the subscriber so it's not recreated on each body call
    @State private var subscriber = ClosureAuthStateSubscriber()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                subscriber.stateChangeHandler = onStateChange
                AuthStateService.shared.subscribe(subscriber)
            }
            .onDisappear {
                AuthStateService.shared.unsubscribe(subscriber)
            }
    }
}

/// Internal class that wraps a closure in an AuthStateSubscriber
private class ClosureAuthStateSubscriber: AuthStateSubscriber {
    var stateChangeHandler: ((AuthState, AuthState?) -> Void)?
    
    func onAuthStateChanged(newState: AuthState, previousState: AuthState?) {
        stateChangeHandler?(newState, previousState)
    }
} 