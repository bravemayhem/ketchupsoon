import XCTest
import SwiftUI
@testable import ketchupsoon

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
    
    func testFriendSheetPresenterModifier() {
        // Given
        let testFriend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        let selectedFriend = Binding.constant(testFriend)
        let sut = Text("Test").friendSheetPresenter(selectedFriend: selectedFriend)
        
        // When
        let mirror = Mirror(reflecting: sut)
        
        // Then
        XCTAssertTrue(mirror.description.contains("FriendSheetPresenter"))
    }
    
    func testFriendSheetPresenterEnvironment() {
        // Given
        let testFriend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        @State var selectedFriend: Friend? = testFriend
        
        let view = NavigationStack {
            Text("Test")
                .friendSheetPresenter(selectedFriend: $selectedFriend)
        }
        
        // When
        let mirror = Mirror(reflecting: view)
        let presenterExists = mirror.children.contains { child in
            String(describing: type(of: child.value)).contains("FriendSheetPresenter")
        }
        
        // Then
        XCTAssertTrue(presenterExists)
    }
    
    func testFriendSheetPresenterBinding() {
        // Given
        let testFriend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        var selectedFriend: Friend? = nil
        let binding = Binding(
            get: { selectedFriend },
            set: { selectedFriend = $0 }
        )
        let presenter = FriendSheetPresenter(selectedFriend: binding)
        
        // When
        presenter.showFriendDetails(for: testFriend)
        
        // Then
        XCTAssertEqual(selectedFriend?.name, testFriend.name)
        XCTAssertEqual(selectedFriend?.phoneNumber, testFriend.phoneNumber)
    }
    
    func testFriendSheetPresenterContent() {
        // Given
        let testFriend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        @State var selectedFriend: Friend? = nil
        let content = Text("Test")
            .friendSheetPresenter(selectedFriend: $selectedFriend)
        
        // When
        let mirror = Mirror(reflecting: content)
        
        // Then
        // Verify that the content has sheet modifiers
        let hasSheetModifiers = mirror.children.contains { child in
            String(describing: child.value).contains("sheet")
        }
        XCTAssertTrue(hasSheetModifiers)
    }
} 
