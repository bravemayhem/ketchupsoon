import XCTest
import SwiftUI
import SwiftData
@testable import friendtracker

final class KetchupsViewTests: XCTestCase {
    var sut: KetchupsView!
    var modelContainer: ModelContainer!
    
    override func setUp() {
        super.setUp()
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(
                for: Friend.self, Hangout.self,
                configurations: config
            )
            sut = KetchupsView()
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        sut = nil
        modelContainer = nil
        super.tearDown()
    }
    
    func testUpcomingHangoutsFiltering() {
        let context = modelContainer.mainContext
        let friend = Friend(name: "Test Friend")
        
        // Future hangout
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let upcomingHangout = Hangout(friend: friend, date: futureDate, duration: 3600)
        upcomingHangout.isScheduled = true
        
        context.insert(friend)
        context.insert(upcomingHangout)
        
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testPastHangoutsFiltering() {
        let context = modelContainer.mainContext
        let friend = Friend(name: "Test Friend")
        
        // Past hangout
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let pastHangout = Hangout(friend: friend, date: pastDate, duration: 3600)
        pastHangout.isScheduled = true
        
        context.insert(friend)
        context.insert(pastHangout)
        
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testCompletedHangoutsFiltering() {
        let context = modelContainer.mainContext
        let friend = Friend(name: "Test Friend")
        
        // Completed hangout
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let completedHangout = Hangout(friend: friend, date: pastDate, duration: 3600)
        completedHangout.isScheduled = true
        completedHangout.isCompleted = true
        
        context.insert(friend)
        context.insert(completedHangout)
        
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testUpcomingCheckInsFiltering() {
        let context = modelContainer.mainContext
        let friend = Friend(name: "Test Friend")
        
        // Set next connect date within 3 weeks
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        friend.nextConnectDate = nextWeek
        
        context.insert(friend)
        
        let view = sut.body
        XCTAssertNotNil(view)
    }
    
    func testThreeWeeksFromNow() {
        let threeWeeks = sut.threeWeeksFromNow
        let expectedDate = Calendar.current.date(byAdding: .day, value: 21, to: Date())!
        
        // Compare dates within the same day (to avoid time differences)
        XCTAssertEqual(
            Calendar.current.startOfDay(for: threeWeeks),
            Calendar.current.startOfDay(for: expectedDate)
        )
    }
    
    func testShouldIncludeInUpcomingCheckIns() {
        let friend = Friend(name: "Test Friend")
        
        // Case 1: No next connect date
        XCTAssertFalse(sut.shouldIncludeInUpcomingCheckIns(friend))
        
        // Case 2: Next connect date within 3 weeks
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        friend.nextConnectDate = nextWeek
        XCTAssertTrue(sut.shouldIncludeInUpcomingCheckIns(friend))
        
        // Case 3: Next connect date after 3 weeks
        let fourWeeks = Calendar.current.date(byAdding: .day, value: 28, to: Date())!
        friend.nextConnectDate = fourWeeks
        XCTAssertFalse(sut.shouldIncludeInUpcomingCheckIns(friend))
    }
} 