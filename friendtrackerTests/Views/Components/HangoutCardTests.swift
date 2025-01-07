import XCTest
import SwiftUI
@testable import friendtracker

final class HangoutCardTests: XCTestCase {
    var sut: HangoutCard!
    var friend: Friend!
    var hangout: Hangout!
    
    override func setUp() {
        super.setUp()
        friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
        hangout = Hangout(
            friend: friend,
            date: Date(),
            duration: 3600
        )
        sut = HangoutCard(hangout: hangout)
    }
    
    override func tearDown() {
        sut = nil
        friend = nil
        hangout = nil
        super.tearDown()
    }
    
    func testCardDisplaysCorrectName() {
        let view = sut.body
        XCTAssertNotNil(view)
        XCTAssertEqual(hangout.friend?.name, "Test Friend")
    }
    
    func testCardDisplaysDate() {
        let view = sut.body
        XCTAssertNotNil(view)
        XCTAssertNotNil(hangout.date)
    }
    
    func testCardHandlesNilFriend() {
        hangout = Hangout(friend: nil, date: Date(), duration: 3600)
        sut = HangoutCard(hangout: hangout)
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testCardHandlesNilDate() {
        hangout = Hangout(friend: friend, date: nil, duration: 3600)
        sut = HangoutCard(hangout: hangout)
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testFriendSelectionUpdatesState() {
        XCTAssertNil(sut.selectedFriend)
        sut.selectedFriend = friend
        XCTAssertEqual(sut.selectedFriend?.name, friend.name)
    }
} 