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
    
    func testDescriptionForEmptyAllDayEvent() {
        let start = "2016 April 10".date(format: DateFormat.custom("yyyy MMMM d"))
        let end = "2016 April 11".date(format: DateFormat.custom("yyyy MMMM d"))
        let realm = realmProvider.realm()
        try! realm.write {
            event.startDate = start!.absoluteDate
            event.endDate = end!.absoluteDate
        }
        
        guard let desc = event.describe() else {
            XCTFail()
            return
        }
        XCTAssertTrue(desc.contains("This is an all-day, non-recurring event"))
        XCTAssertTrue(desc.contains("It starts from Sunday, April 10, 2016"))
        XCTAssertTrue(desc.contains("It ends on Monday, April 11, 2016"))
        XCTAssertTrue(desc.contains("And the author didn't write anything else"))
    }
}
