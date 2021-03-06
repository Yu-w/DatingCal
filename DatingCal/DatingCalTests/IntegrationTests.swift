//
//  MultiUserTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/26/17.
//
//

import XCTest
import SwiftyJSON
import PromiseKit
import RealmSwift
import Alamofire
@testable import DatingCal

/// This is an itegration test
class IntegrationTests : GoogleTests {
    
    lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.client, self.realmProvider)
    }()
    
    /// This is a helper function that tests whether removing a user will delete its events
    /// :param shouldDeleteEvents: pass in the ids of events that should be deleted
    /// :param shouldDeleteCalendars: pass in the ids of calendars that should be deleted
    func testDeletingEvents(_ shouldDeleteEvents: [String], _ shouldDeleteCalendars: [String]) -> Void {
        guard let user = UserModel.getPrimaryUser(self.realmProvider) else {
            XCTFail()
            return
        }
        let originalUserId = user.id
        user.remove(self.realmProvider)
        let realm = self.realmProvider.realm()
        XCTAssertEqual(realm.objects(UserModel.self).filter{$0.id==originalUserId}.count, 0)
        XCTAssertEqual(realm.objects(CalendarModel.self).filter{ calendar in
            shouldDeleteCalendars.contains(where: {$0 == calendar.id})
        }.count, 0)
        XCTAssertEqual(realm.objects(EventModel.self).filter{ event in
            shouldDeleteEvents.contains(where: {$0 == event.id})
        }.count, 0)
    }
    
    /// Test single-user functionalities
    /// Test that events created with "createEvents"
    ///  will be deleted upon logout
    func testSingleUserEventsWillBeDeleted1() {
        let calendarId = "123"
        let eventId = "234"
        let userId = "345"
        
        addDefaultUser(userId)
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, calendarId, [], {
            self.setClientForCreatingEvent(eventId)
        })
        
        let wantedEvent = getDummyNewEvent()
        testPromise(googleCalendar.createEvent(wantedEvent).then { _ -> Void in
            self.testDeletingEvents([eventId], [calendarId])
        })
    }
    
    /// Test single-user functionalities
    /// Test that events fetched from Google
    ///  will be deleted upon logout
    func testSingleUserEventsWillBeDeleted2() {
        let calendarId = "123"
        let userId = "345"
        var eventIds : [String] = []
        
        var wantedEvents : [Parameters] = []
        let wantedEvent = getDummyEventParams()
        for i in 1...10 {
            var copy = wantedEvent
            let id = "\(i)"
            copy["id"] = id
            eventIds.append(id)
            wantedEvents.append(wantedEvent)
        }
        
        addDefaultUser(userId)
        
        self.setClientForListingEvents(wantedEvents, true)
        
        testPromise(googleCalendar.listEventLists(calendarId).then { _ -> Void in
            self.testDeletingEvents(eventIds, [calendarId])
        })
    }
    
    /// Test multi-user functionalities
    /// Test that events created with "createEvents"
    ///  will be deleted upon logout
    /// Specifically, we log out the current user.
    func testMultiUserEventsWillBeDeleted1A() {
        let calendarId = "123B"
        let eventId = "234B"
        let userId = "345B"
        
        addDefaultUser(userId)
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, calendarId, [], {
            self.setClientForCreatingEvent(eventId)
        })
        
        let wantedEvent = getDummyNewEvent()
        testPromise(googleCalendar.createEvent(wantedEvent).then { _ -> Promise<Void> in
            let calendarId = "123A"
            let eventId = "234A"
            let userId = "345A"
            
            self.addDefaultUser(userId)
            
            /// First, respond to 'list calendars' API
            self.setClientForCreatingCalendar(false, calendarId, [], {
                self.setClientForCreatingEvent(eventId)
            })
            
            let wantedEvent = self.getDummyNewEvent()
            return self.googleCalendar.createEvent(wantedEvent).then { _ -> Void in
                self.testDeletingEvents([eventId], [calendarId])
            }
        })
    }
    
    /// Test multi-user functionalities
    /// Test that events fetched from Google
    ///  will be deleted upon logout
    /// Specifically, we log out the current user.
    func testMultiUserEventsWillBeDeleted2A() {
        let calendarId = "123B"
        let userId = "345B"
        var eventIds : [String] = []
        
        var wantedEvents : [Parameters] = []
        let wantedEvent = getDummyEventParams()
        for i in 1...10 {
            var copy = wantedEvent
            let id = "\(i)B"
            copy["id"] = id
            eventIds.append(id)
            wantedEvents.append(wantedEvent)
        }
        
        addDefaultUser(userId)
        
        self.setClientForListingEvents(wantedEvents, true)
        
        testPromise(googleCalendar.listEventLists(calendarId).then { _ -> Promise<Void> in
            let calendarId = "123A"
            let userId = "345A"
            var eventIds : [String] = []
            
            var wantedEvents : [Parameters] = []
            let wantedEvent = self.getDummyEventParams()
            for i in 1...10 {
                var copy = wantedEvent
                let id = "\(i)A"
                copy["id"] = id
                eventIds.append(id)
                wantedEvents.append(wantedEvent)
            }
            
            self.addDefaultUser(userId)
            
            self.setClientForListingEvents(wantedEvents, true)
            
            return self.googleCalendar.listEventLists(calendarId).then { _ -> Void in
                self.testDeletingEvents(eventIds, [calendarId])
            }
        })
    }
}
