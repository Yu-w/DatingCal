//
//  DatingCalTests.swift
//  DatingCalTests
//
//  Created by Wang Yu on 4/9/17.
//
//

import XCTest
import SwiftyJSON
import PromiseKit
@testable import DatingCal

/// Test the "GoogleCalendar" class.
class CalendarTests: AsyncTests {
    
    var client = FakeHTTPClient()
    var realmProvider = FakeRealmProvider()
    
    lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.client, self.realmProvider)
    }()
    
    /// A helper function to create fake google apis.
    /// :param forbidCreation: if true, the test case will fail if any new calendar is created
    /// :param createdId: the id of any created calendar
    /// :param existingCalendars: the calendars to return whenever Google is required to list existing calendar
    private func setClientForCreatingCalendar(_ forbidCreation: Bool, _ createdId: String, _ existingCalendars: Any) {
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
    
    func testGetOurCalendarWillCreateCalendar() {
        let createdId = "123"
        let wantedName = googleCalendar.kNameOfOurCalendar
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, createdId, [])
        
        testPromise(googleCalendar.getOurCalendar().then { calendar -> Void in
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let result = realm.objects(CalendarModel.self).filter({
                cal in cal.name == wantedName
            })
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.id, createdId)
            XCTAssertEqual(result.first!.name, wantedName)
            
            /// Examine returned calendar object
            XCTAssertEqual(calendar, result.first!)
        })
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Realm Database
    func testGetOurCalendarWillNotDuplicate1() {
        /// First, respond to 'list calendars' API
        let originalId = "100"
        let createdId = "123"
        setClientForCreatingCalendar(false, originalId, [])
        
        testPromise(googleCalendar.getOurCalendar().then { calendar -> Promise<CalendarModel> in
            XCTAssertEqual(calendar.id, originalId)
            
            /// Try calling getOurCalendar() again
            var existingCalendar = calendar.unParse()
            existingCalendar["id"] = calendar.id
            self.setClientForCreatingCalendar(true, createdId, [existingCalendar])
            return self.googleCalendar.getOurCalendar()
        })
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Google Calendar
    func testGetOurCalendarWillNotDuplicate2() {
        /// originalId: the ID of original 'DatingCal' calendar
        /// createdId: the ID of possibly created, duplicated calendar
        let originalId = "100"
        let createdId = "123"
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(true, createdId, [[
            "id": originalId,
            "summary": self.googleCalendar.kNameOfOurCalendar
            ]])
        
        testPromise(googleCalendar.getOurCalendar())
    }
}
