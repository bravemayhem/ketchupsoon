import XCTest
import SwiftUI
@testable import friendtracker

final class FriendSheetPresenterTests: XCTestCase {
    var sut: FriendSheetPresenter!
    var selectedFriend: Friend?
    
    override func setUp() {
        super.setUp()
        selectedFriend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        sut = FriendSheetPresenter(selectedFriend: .constant(selectedFriend))
    }
    
    override func tearDown() {
        sut = nil
        selectedFriend = nil
        super.tearDown()
    }
    
    func testShowFriendDetails() {
        // Given
        let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        
        // When
        sut.showFriendDetails(for: friend)
        
        // Then
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
        XCTAssertTrue(sut.showingFriendSheet)
    }
    
    func testShowScheduler() {
        // Given
        let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        
        // When
        sut.showScheduler(for: friend)
        
        // Then
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
        XCTAssertTrue(sut.showingScheduler)
    }
    
    func testShowMessage() {
        // Given
        let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        
        // When
        sut.showMessage(for: friend)
        
        // Then
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
        XCTAssertTrue(sut.showingMessageSheet)
    }
    
    func testShowFrequencyPicker() {
        // Given
        let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        
        // When
        sut.showFrequencyPicker(for: friend)
        
        // Then
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
        XCTAssertTrue(sut.showingFrequencyPicker)
    }
    
    func testShowActionSheet() {
        // Given
        let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        
        // When
        sut.showActionSheet(for: friend)
        
        // Then
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
        XCTAssertTrue(sut.showingActionSheet)
    }
} 