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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let createdId = "123"
        var isCalled = [false]
        var wantedName = [""]
        
        self.client.setHandler { url, method, params in
            XCTAssertNotNil(params)
            var json = JSON(params!)
            json["id"].string = createdId
            isCalled[0] = true
            wantedName[0] = params!["summary"] as! String
            return Promise(value: json)
        }
        
        _ = self.googleCalendar.getOurCalendar().then { calendar -> Promise<CalendarModel> in
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
            
            /// Try calling getOurCalendar() again
            self.client.setHandler { url, method, params in
                XCTFail("If 'DatingCal' calendar is already created, "
                    + "calling getOurCalendar() should not recreate our calendar.")
                return Promise { _, reject in reject(FakeHTTPError.InvalidOperation) }
            }
            return self.googleCalendar.getOurCalendar()
        }.always {
            self.finishTest()
        }
    }
    
}
