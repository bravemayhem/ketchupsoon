import XCTest
import SwiftUI
import ViewInspector
@testable import ketchupsoon

// Make the view inspectable
extension UnscheduledCheckInCard: Inspectable {}

final class UnscheduledCheckInCardTests: XCTestCase {
    var sut: UnscheduledCheckInCard!
    var friend: Friend!
    var scheduleTapped: Bool!
    var messageTapped: Bool!
    
    override func setUp() {
        super.setUp()
        friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        scheduleTapped = false
        messageTapped = false
        
        sut = UnscheduledCheckInCard(
            friend: friend,
            onScheduleTapped: { self.scheduleTapped = true },
            onMessageTapped: { self.messageTapped = true }
        )
    }
    
    override func tearDown() {
        sut = nil
        friend = nil
        scheduleTapped = nil
        messageTapped = nil
        super.tearDown()
    }
    
    func testCardDisplaysCorrectName() throws {
        let view = sut.body
        
        // Find and verify the friend's name text
        let nameText = try view.inspect().find(ViewType.Text.self) { text in
            try text.string() == "Test Friend"
        }
        XCTAssertEqual(try nameText.string(), "Test Friend")
    }
    
    func testScheduleButtonTriggersCallback() throws {
        // Find and tap the Schedule button
        try sut.inspect().find(button: "Schedule").tap()
        XCTAssertTrue(scheduleTapped)
    }
    
    func testMessageButtonTriggersCallback() throws {
        // Find and tap the Message button
        try sut.inspect().find(button: "Message").tap()
        XCTAssertTrue(messageTapped)
    }
    
    func testMessageButtonOnlyShowsWithPhoneNumber() throws {
        // Friend with phone number
        let friendWithPhone = Friend(name: "Has Phone", phoneNumber: "123")
        let viewWithPhone = UnscheduledCheckInCard(
            friend: friendWithPhone,
            onScheduleTapped: {},
            onMessageTapped: {}
        )
        XCTAssertNoThrow(try viewWithPhone.inspect().find(button: "Message"))
        
        // Friend without phone number
        let friendWithoutPhone = Friend(name: "No Phone", phoneNumber: nil)
        let viewWithoutPhone = UnscheduledCheckInCard(
            friend: friendWithoutPhone,
            onScheduleTapped: {},
            onMessageTapped: {}
        )
        XCTAssertThrowsError(try viewWithoutPhone.inspect().find(button: "Message"))
    }
    
    func testFrequencyTextDisplaysCorrectly() throws {
        // Friend with frequency
        friend.catchUpFrequency = .weekly
        let frequencyText = try sut.inspect().find(ViewType.Text.self) { text in
            try text.string().contains("weekly")
        }
        XCTAssertTrue(try frequencyText.string().contains("weekly"))
        
        // Friend without frequency
        friend.catchUpFrequency = nil
        let viewWithoutFrequency = sut.body
        XCTAssertThrowsError(try viewWithoutFrequency.inspect().find(ViewType.Text.self) { text in
            try text.string().contains("catch-up")
        })
    }
} 
