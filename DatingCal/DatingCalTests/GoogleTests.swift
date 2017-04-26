//
//  GoogleTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/24/17.
//
//

import Foundation
import SwiftyJSON
import PromiseKit
import Alamofire
import XCTest
@testable import DatingCal

/// This is supposed to be used as a base class.
class GoogleTests : AsyncTests {
    
    var client = FakeHTTPClient()
    var realmProvider = FakeRealmProvider()
    
    /// Add a default user to database without performing a real login.
    func addDefaultUser(_ userId: String) {
        let realm = realmProvider.realm()
        try! realm.write {
            let user = UserModel()
            user.id = userId
            user.name = "TEST"
            realm.add(user)
        }
    }
    
    /// generate a new event template
    /// useful if you want to create a new event.
    func getDummyNewEvent() -> EventModel {
        let wantedEvent = EventModel()
        wantedEvent.summary = "ABC"
        wantedEvent.desc = "TEST"
        wantedEvent.startTime = Date()
        wantedEvent.endTime = Date() + TimeInterval(Date().day)
        return wantedEvent
    }
    
    /// generate a new event template, and return it as HTTP Parameters
    /// useful if you want to simulate getting existing events.
    func getDummyEventParams() -> Parameters {
        var wantedEvent : Parameters = [:]
        wantedEvent["summary"] = "ABC"
        wantedEvent["desc"] = "TEST"
        wantedEvent["startTime"] = Date()
        wantedEvent["endTime"] = Date() + TimeInterval(Date().day)
        return wantedEvent
    }
    
    /// A helper function to fake APIs that create google calendar
    /// :param forbidCreation: if true, the test case will fail if any new calendar is created
    /// :param createdId: the id of any created calendar
    /// :param existingCalendars: the calendars to return whenever Google is required to list existing calendar
    /// :param afterCreation: a callback, which is called after all handlers have finished execution, to add more handlers.
    ///                          NOTE: this parameter requires fobidCreation = false
    func setClientForCreatingCalendar(_ forbidCreation: Bool,
                                              _ createdId: String,
                                              _ existingCalendars: Any,
                                              _ afterCreation: @escaping ()->Void={}) {
        self.client.setHandler { url, method, params in
            /// Then, respond to 'create calendar' API
            if forbidCreation {
                self.client.setHandler { url, method, params in
                    XCTFail("If 'DatingCal' calendar is already created, "
                        + "calling getOurCalendar() should not recreate our calendar.")
                    return Promise(error: FakeHTTPError.InvalidOperation)
                }
            } else {
                self.client.setHandler { url, method, params in
                    afterCreation()
                    XCTAssertNotNil(params)
                    var json = JSON(params!)
                    json["id"].string = createdId
                    return Promise(value: json)
                }
            }
            let params = [
                "items": existingCalendars
            ]
            return Promise(value: JSON(params))
        }
    }
    
    /// A helper function to fake APIs that create events.
    /// Make sure to handle getOurCalendar() first, before using this handler.
    /// :param createdId: the id of any created event
    func setClientForCreatingEvent(_ createdId: String) {
        self.client.setHandler { url, method, params in
            XCTAssertNotNil(params)
            var json = JSON(params!)
            json["id"].string = createdId
            return Promise(value: json)
        }
    }
    
    /// A helper function to fake APIs that fetch the complete list of events.
    func setClientForListingEvents(_ events: [Parameters], _ testMultiPage: Bool=false) {
        let nextPageToken = "A ToKeN"
        var first : [Parameters] = []
        var second : [Parameters] = []
        for i in 0...(events.count-1) {
            if i < events.count / 2 {
                first.append(events[i])
            } else {
                second.append(events[i])
            }
        }
        self.client.setHandler { url, method, params in
            var result : Parameters = [:]
            if testMultiPage {
                result["items"] = first
                result["nextPageToken"] = nextPageToken
                self.client.setHandler { url,method,params in
                    XCTAssertNotNil(params!)
                    XCTAssertTrue(params!.keys.contains("pageToken"))
                    let pageToken = params!["pageToken"] as! String
                    XCTAssertEqual(nextPageToken, pageToken)
                    return Promise(value: JSON(["items": second]))
                }
            } else {
                result["items"] = events
            }
            let json = JSON(result)
            return Promise(value: json)
        }
    }
}

extension EventModel {
    func assertEqual(_ event: EventModel) {
        XCTAssertEqual(self.summary, event.summary)
        XCTAssertEqual(self.desc, event.desc)
        if let startTime = self.startTime {
            XCTAssertTrue(startTime.similar(event.startTime!))
        }
        if let endTime = self.endTime {
            XCTAssertTrue(endTime.similar(event.endTime!))
        }
        if let startDate = self.startDate {
            XCTAssertTrue(startDate.similar(event.startDate!))
        }
        if let endDate = self.endDate {
            XCTAssertTrue(endDate.similar(event.endDate!))
        }
        XCTAssertTrue(self.endTime!.similar(event.endTime!))
    }
}

extension Date {
    func similar(_ date: Date) -> Bool {
        return string() == date.string()
    }
}
