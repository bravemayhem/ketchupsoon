//
//  DisplayConfettiModifier.swift
//  friendtracker
//
//  Created by Brooklyn Beltran on 2/20/25.
//

import SwiftUI

struct DisplayConfettiModifier: ViewModifier {
    @Binding var isActive: Bool {
        didSet {
            print("🎉 Confetti isActive changed to: \(isActive)")
            if !isActive {
                opacity = 1
            }
        }
    }
    @State private var opacity = 1.0 {
        didSet {
            print("🎉 Confetti opacity changed to: \(opacity)")
            if opacity == 0 {
                isActive = false
            }
        }
    }
    
    private let animationTime = 1.5
    private let fadeTime = 0.5

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .sensoryFeedback(.success, trigger: isActive)
                .task(id: isActive) {
                    print("🎉 Starting confetti animation sequence")
                    await handleAnimationSequence()
                }
        } else {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .task(id: isActive) {
                    print("🎉 Starting confetti animation sequence")
                    await handleAnimationSequence()
                }
        }
    }

    private func handleAnimationSequence() async {
        do {
            print("🎉 Waiting for \(animationTime) seconds before fade")
            try await Task.sleep(nanoseconds: UInt64(animationTime * 1_000_000_000))
            print("🎉 Starting fade animation")
            withAnimation(.easeOut(duration: fadeTime)) {
                opacity = 0
            }
        } catch {
            print("🎉 Error in animation sequence: \(error)")
        }
    }
}

extension View {
    func displayConfetti(isActive: Binding<Bool>) -> some View {
        self.modifier(DisplayConfettiModifier(isActive: isActive))
    }
}

#Preview {
    Text("Previewing Confetti")
        .displayConfetti(isActive: .constant(true))
}
