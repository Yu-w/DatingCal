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
import RealmSwift
@testable import DatingCal

/// Test the "GoogleCalendar" class.
/// (Add by Mark Yu.)
class CalendarTests: GoogleTests {
    
    lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.client, self.realmProvider)
    }()
    
    /// ------------------- TEST: getOurCalendar
    
    func testGetOurCalendarWillCreateCalendar() {
        let createdId = "123"
        let userId = "345"
        let wantedName = googleCalendar.kNameOfOurCalendar
        
        addDefaultUser(userId)
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, createdId, [])
        
        testPromise(googleCalendar.ensureOurCalendar().then { _ -> Void in
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let currUser = UserModel.getPrimaryUser(self.realmProvider)
            let calendar = currUser?.datingCalendar
            XCTAssertNotNil(calendar)
            let result = realm.objects(CalendarModel.self).filter({
                cal in cal.name == wantedName
            })
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.id, createdId)
            XCTAssertEqual(result.first!.name, wantedName)
            
            /// Examine returned calendar object
            XCTAssertEqual(calendar!, result.first!)
        })
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Realm Database
    func testGetOurCalendarWillNotDuplicate1() {
        /// First, respond to 'list calendars' API
        let originalId = "100"
        let userId = "345"
        let createdId = "123"
        
        addDefaultUser(userId)
        setClientForCreatingCalendar(false, originalId, [])
        testPromise(googleCalendar.ensureOurCalendar().then { _ -> Promise<Void> in
            /// Read from database to make sure calendar is cached
            let currUser = UserModel.getPrimaryUser(self.realmProvider)
            let _calendar = currUser?.datingCalendar
            let calendar = _calendar!
            XCTAssertNotNil(calendar)
            XCTAssertEqual(calendar.id, originalId)
            
            /// Try calling getOurCalendar() again
            var existingCalendar = calendar.unParse()
            existingCalendar["id"] = calendar.id
            self.setClientForCreatingCalendar(true, createdId, [existingCalendar])
            return self.googleCalendar.ensureOurCalendar()
        })
    }
    
    /// We should not create 'DatingCal' calendar again
    ///  if it's already in Google Calendar
    func testGetOurCalendarWillNotDuplicate2() {
        /// originalId: the ID of original 'DatingCal' calendar
        /// createdId: the ID of possibly created, duplicated calendar
        let originalId = "100"
        let createdId = "123"
        let userId = "345"
        
        addDefaultUser(userId)
        setClientForCreatingCalendar(true, createdId, [[
            "id": originalId,
            "summary": self.googleCalendar.kNameOfOurCalendar
            ]])
        
        testPromise(googleCalendar.ensureOurCalendar())
    }
}
