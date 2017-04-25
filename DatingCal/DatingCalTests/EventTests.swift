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
import Alamofire
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
            XCTAssertNotNil(result.first!.startTime)
            XCTAssertNotNil(result.first!.endTime)
            result.first!.assertEqual(wantedEvent)
        })
    }
    
    /// ------------------- TEST: createEvent
    
    /// Test whether all events listed by the API is correctly parsed
    func testListAllEventsInCalendar(_ shouldUseNextPageToken: Bool) {
        let calendarId = "123"
        
        var wantedEvents : [Parameters] = []
        var wantedEvent : Parameters = [:]
        wantedEvent["summary"] = "ABC"
        wantedEvent["desc"] = "TEST"
        wantedEvent["startTime"] = Date()
        wantedEvent["endTime"] = Date() + TimeInterval(Date().day)
        for i in 1...10 {
            var copy = wantedEvent
            copy["id"] = "\(i)"
            wantedEvents.append(wantedEvent)
        }
        
        self.setClientForListingEvents(wantedEvents, shouldUseNextPageToken)
        
        testPromise(googleCalendar.listEventLists(calendarId).then { list -> Void in
            XCTAssertEqual(list.count, wantedEvents.count)
            XCTAssertEqual(list, wantedEvents.map(JSON.init))
        })
    }
    
    /// Test whether all events listed by the API is correctly parsed
    /// This does not test the usage of "nextPageToken"
    func testListAllEventsInCalendar1() {
        self.testListAllEventsInCalendar(false)
    }
    
    /// Test whether all events listed by the API is correctly parsed
    /// This DOES test the usage of "nextPageToken"
    func testListAllEventsInCalendar2() {
        self.testListAllEventsInCalendar(true)
    }
}
