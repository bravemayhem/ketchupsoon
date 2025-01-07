import XCTest
import SwiftUI
@testable import friendtracker

final class FriendListStyleTests: XCTestCase {
    func testFriendListStyleModifier() {
        // Given
        let sut = Text("Test")
        
        // When
        let modifiedView = sut.friendListStyle()
        
        // Then
        let mirror = Mirror(reflecting: modifiedView)
        XCTAssertTrue(mirror.description.contains("FriendListStyle"))
    }
    
    func testFriendCardStyleModifier() {
        // Given
        let sut = Text("Test")
        
        // When
        let modifiedView = sut.friendCardStyle()
        
        // Then
        let mirror = Mirror(reflecting: modifiedView)
        XCTAssertTrue(mirror.description.contains("FriendCardStyle"))
    }
    
    func testFriendListStyleProperties() {
        // Given
        let sut = FriendListStyle()
        let content = Text("Test")
        
        // When
        let modifiedView = sut.body(content: content)
        
        // Then
        let mirror = Mirror(reflecting: modifiedView)
        let children = Array(mirror.children)
        
        // Verify the view has the expected modifiers
        XCTAssertTrue(children.contains { $0.label?.contains("listStyle") ?? false })
        XCTAssertTrue(children.contains { $0.label?.contains("background") ?? false })
    }
    
    func testFriendCardStyleProperties() {
        // Given
        let sut = FriendCardStyle()
        let content = Text("Test")
        
        // When
        let modifiedView = sut.body(content: content)
        
        // Then
        let mirror = Mirror(reflecting: modifiedView)
        let children = Array(mirror.children)
        
        // Verify the view has the expected modifiers
        XCTAssertTrue(children.contains { $0.label?.contains("listRowInsets") ?? false })
        XCTAssertTrue(children.contains { $0.label?.contains("listRowBackground") ?? false })
        XCTAssertTrue(children.contains { $0.label?.contains("listRowSeparator") ?? false })
    }
} 