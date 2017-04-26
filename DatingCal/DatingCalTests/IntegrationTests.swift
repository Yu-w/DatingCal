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
    
    /// Test single-user functionalities
    /// Test that events created with "createEvents"
    ///  will be deleted upon logout
    func singleUserEventsWillBeDeleted1() {
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
            guard let user = UserModel.getPrimaryUser(self.realmProvider) else {
                XCTFail()
                return
            }
            user.remove(self.realmProvider)
            let realm = self.realmProvider.realm()
            XCTAssertEqual(realm.objects(UserModel.self).count, 0)
            XCTAssertEqual(realm.objects(CalendarModel.self).count, 0)
            XCTAssertEqual(realm.objects(EventModel.self).count, 0)
        })
    }
    
    /// Test single-user functionalities
    /// Test that events fetched from Google
    ///  will be deleted upon logout
    func singleUserEventsWillBeDeleted2() {
        let calendarId = "123"
        let userId = "345"
        
        var wantedEvents : [Parameters] = []
        let wantedEvent = getDummyEventParams()
        for i in 1...10 {
            var copy = wantedEvent
            copy["id"] = "\(i)"
            wantedEvents.append(wantedEvent)
        }
        
        addDefaultUser(userId)
        
        self.setClientForListingEvents(wantedEvents, true)
        
        testPromise(googleCalendar.listEventLists(calendarId).then { list -> Void in
            guard let user = UserModel.getPrimaryUser(self.realmProvider) else {
                XCTFail()
                return
            }
            user.remove(self.realmProvider)
            let realm = self.realmProvider.realm()
            XCTAssertEqual(realm.objects(UserModel.self).count, 0)
            XCTAssertEqual(realm.objects(CalendarModel.self).count, 0)
            XCTAssertEqual(realm.objects(EventModel.self).count, 0)
        })
    }
}
