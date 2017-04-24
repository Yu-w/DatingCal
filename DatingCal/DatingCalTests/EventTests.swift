//
//  EventTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/24/17.
//
//

import XCTest
import SwiftyJSON
import PromiseKit
import RealmSwift
@testable import DatingCal

class EventTests : GoogleTests {
    
    lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.client, self.realmProvider)
    }()
    
    /// ------------------- TEST: createEvent
    
    func testCreateEventResultExists() {
        let calendarId = "123"
        let eventId = "234"
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, calendarId, [], {
            self.setClientForCreatingEvent(eventId)
        })
        
        let wantedEvent = EventModel()
        wantedEvent.summary = "ABC"
        wantedEvent.desc = "TEST"
        wantedEvent.startTime = Date()
        wantedEvent.endTime = Date() + TimeInterval(Date().day)
        
        testPromise(googleCalendar.createEvent(wantedEvent).then { _ -> Void in
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let result = realm.objects(EventModel.self).filter({
                event in event.summary == wantedEvent.summary
            })
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.id, eventId)
            XCTAssertEqual(result.first!.summary, wantedEvent.summary)
            XCTAssertEqual(result.first!.desc, wantedEvent.desc)
            XCTAssertNotNil(result.first!.startTime)
            XCTAssertNotNil(result.first!.endTime)
            XCTAssertTrue(result.first!.startTime!.similar(wantedEvent.startTime!))
            XCTAssertTrue(result.first!.endTime!.similar(wantedEvent.endTime!))
        })
    }
}

extension Date {
    func similar(_ date: Date) -> Bool {
        return string() == date.string()
    }
}
