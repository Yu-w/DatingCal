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
    
    func testGetOurCalendarWillCreateCalendar() {
        let createdId = "123"
        var isCalled = [false]
        var wantedName = [""]
        
        /// First, respond to 'list calendars' API
        self.client.setHandler { url, method, params in
            /// Then, respond to 'create calendar' API
            self.client.setHandler { url, method, params in
                XCTAssertNotNil(params)
                var json = JSON(params!)
                json["id"].string = createdId
                isCalled[0] = true
                wantedName[0] = params!["summary"] as! String
                return Promise(value: json)
            }
            let params = [
                "items": []
            ]
            return Promise(value: JSON(params))
        }
        
        _ = self.googleCalendar.getOurCalendar().then { calendar -> Void in
            XCTAssert(isCalled[0])
            
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let result = realm.objects(CalendarModel.self).filter({
                cal in cal.name == wantedName[0]
            })
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.id, createdId)
            XCTAssertEqual(result.first!.name, wantedName[0])
            
            /// Examine returned calendar object
            XCTAssertEqual(calendar, result.first!)
        }.always {
            self.finishTest()
        }
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Realm Database
    func testGetOurCalendarWillNotDuplicate1() {
        let createdId = "123"
        var isCalled = [false]
        var wantedName = [""]
        
        /// First, respond to 'list calendars' API
        self.client.setHandler { url, method, params in
            /// Then, respond to 'create calendar' API
            self.client.setHandler { url, method, params in
                XCTAssertNotNil(params)
                var json = JSON(params!)
                json["id"].string = createdId
                isCalled[0] = true
                wantedName[0] = params!["summary"] as! String
                return Promise(value: json)
            }
            let params = [
                "items": []
            ]
            return Promise(value: JSON(params))
        }
        
        _ = self.googleCalendar.getOurCalendar().then { calendar -> Promise<CalendarModel> in
            XCTAssert(isCalled[0])

            /// Try calling getOurCalendar() again
            self.client.setHandler { url, method, params in
                self.client.setHandler { url, method, params in
                    XCTFail("If 'DatingCal' calendar is already created, "
                        + "calling getOurCalendar() should not recreate our calendar.")
                    return Promise(error: FakeHTTPError.InvalidOperation)
                }
                var unparsed = calendar.unParse()
                unparsed["id"] = calendar.id
                let params = [
                    "items": [unparsed]
                ]
                return Promise(value: JSON(params))
            }
            return self.googleCalendar.getOurCalendar()
        }.always {
            self.finishTest()
        }
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Google Calendar
    func testGetOurCalendarWillNotDuplicate2() {
        /// originalId: the ID of original 'DatingCal' calendar
        /// createdId: the ID of possibly created, duplicated calendar
        let originalId = "100"
        let wantedName = self.googleCalendar.kNameOfOurCalendar
        var isCalled = [false]
        
        /// First, respond to 'list calendars' API
        self.client.setHandler { url, method, params in
            isCalled[0] = true
            
            /// Then, respond to 'create calendar' API
            self.client.setHandler { url, method, params in
                XCTFail("If 'DatingCal' calendar is already created, "
                    + "calling getOurCalendar() should not recreate our calendar.")
                return Promise(error: FakeHTTPError.InvalidOperation)
            }
            
            let params = [
                "items": [[
                    "id": originalId,
                    "summary": self.googleCalendar.kNameOfOurCalendar,
                ]]
            ]
            return Promise(value: JSON(params))
        }
        
        _ = self.googleCalendar.getOurCalendar().then { calendar -> Void in
            XCTAssert(isCalled[0])
            
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let result = realm.objects(CalendarModel.self).filter({
                cal in cal.name == wantedName
            })
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.id, originalId)
            XCTAssertEqual(result.first!.name, wantedName)
            
            /// Examine returned calendar object
            XCTAssertEqual(calendar, result.first!)
        }.always {
            self.finishTest()
        }
    }
}
