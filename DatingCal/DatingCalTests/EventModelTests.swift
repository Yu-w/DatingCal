//
//  UserModelTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/26/17.
//
//

import Foundation
import SwiftyJSON
import PromiseKit
import SwiftDate
import Alamofire
import XCTest
@testable import DatingCal

class EventModelTests : AsyncTests {
    var user = UserModel()
    var calendar = CalendarModel()
    var event = EventModel()
    
    let userName = "abc"
    let calendarName = "def"
    let eventName = "ghi"
    
    let realmProvider = FakeRealmProvider()
    
    /// Setup a calendar with an event that has only a title
    override func setUp() {
        super.setUp()
        
        user = UserModel()
        calendar = CalendarModel()
        event = EventModel()
        
        user.name = userName
        user._isPrimary = true
        calendar.name = calendarName
        event.summary = eventName
        
        let realm = realmProvider.realm()
        try! realm.write {
            realm.add(user)
            realm.add(calendar)
            realm.add(event)
        }
        calendar.addToPrimaryUser(self.realmProvider)
        try! realm.write {
            calendar.events.append(event)
        }
    }
    
    private func testTimeForAllDayEvent(recurring: Bool) {
        let start = "2016 April 10".date(format: DateFormat.custom("yyyy MMMM d"))
        let end = "2016 April 11".date(format: DateFormat.custom("yyyy MMMM d"))
        let realm = realmProvider.realm()
        try! realm.write {
            event.startDate = start!.absoluteDate
            event.endDate = end!.absoluteDate
            if recurring {
                event.setRecurrence(newValue: ["fake rule"])
            }
        }
        
        guard let desc = event.describe() else {
            XCTFail()
            return
        }
        if recurring {
            XCTAssertTrue(desc.contains("This is an all-day, recurring event"))
        } else {
            XCTAssertTrue(desc.contains("This is an all-day, non-recurring event"))
        }
        XCTAssertTrue(desc.contains("It starts from Sunday, April 10, 2016"))
        XCTAssertTrue(desc.contains("It ends on Monday, April 11, 2016"))
    }
    
    private func testTimeForNonAllDayEvent(recurring: Bool) {
        let start = "2016 April 10 20:10".date(format: DateFormat.custom("yyyy MMMM d hh:mm"))
        let end = "2016 April 11 21:22".date(format: DateFormat.custom("yyyy MMMM d hh:mm"))
        let realm = realmProvider.realm()
        try! realm.write {
            event.startTime = start!.absoluteDate
            event.endTime = end!.absoluteDate
            if recurring {
                event.setRecurrence(newValue: ["fake rule"])
            }
        }
        
        guard let desc = event.describe() else {
            XCTFail()
            return
        }
        if recurring {
            XCTAssertTrue(desc.contains("This is a recurring event"))
        } else {
            XCTAssertTrue(desc.contains("This is a non-recurring event"))
        }
        XCTAssertTrue(desc.contains("It starts from Sun, April 10, 2016 8:10 PM"))
        XCTAssertTrue(desc.contains("It ends on Mon, April 11, 2016 9:22 PM"))
    }
    
    private func testDescriptionForExtraDescription(desc: String? = nil) {
        guard let _desc = desc else {
            /// Test event without extra description
            guard let desc = event.describe() else {
                XCTFail()
                return
            }
            XCTAssertTrue(desc.contains("And the author didn't write anything else"))
            return
        }
        
        // Test event with extra description
        let realm = realmProvider.realm()
        try! realm.write {
            event.desc = _desc
        }
        guard let ans = event.describe() else {
            XCTFail()
            return
        }
        XCTAssertTrue(ans.contains("And here are some extra descriptions:\n\n" + _desc))
    }
    
    func testDescriptionForEmptyRecurringAllDayEvent() {
        testTimeForAllDayEvent(recurring: true)
        testDescriptionForExtraDescription(desc: nil)
    }
    
    func testDescriptionForEmptyNonRecurringAllDayEvent() {
        testTimeForAllDayEvent(recurring: false)
        testDescriptionForExtraDescription(desc: nil)
    }
    
    func testDescriptionForEmptyRecurringNonAllDayEvent() {
        testTimeForNonAllDayEvent(recurring: true)
        testDescriptionForExtraDescription(desc: nil)
    }
    
    func testDescriptionForEmptyNonRecurringNonAllDayEvent() {
        testTimeForNonAllDayEvent(recurring: false)
        testDescriptionForExtraDescription(desc: nil)
    }
    
    func testDescriptionForNonEmptyRecurringAllDayEvent() {
        testTimeForAllDayEvent(recurring: true)
        testDescriptionForExtraDescription(desc: "TEST")
    }
    
    func testDescriptionForNonEmptyNonRecurringAllDayEvent() {
        testTimeForAllDayEvent(recurring: false)
        testDescriptionForExtraDescription(desc: "TEST")
    }
    
    func testDescriptionForNonEmptyRecurringNonAllDayEvent() {
        testTimeForNonAllDayEvent(recurring: true)
        testDescriptionForExtraDescription(desc: "TEST")
    }
    
    func testDescriptionForNonEmptyNonRecurringNonAllDayEvent() {
        testTimeForNonAllDayEvent(recurring: false)
        testDescriptionForExtraDescription(desc: "TEST")
    }
}
