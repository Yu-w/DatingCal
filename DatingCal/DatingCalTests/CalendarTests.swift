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
        let wantedName = googleCalendar.kNameOfOurCalendar
        
        /// First, respond to 'list calendars' API
        setClientForCreatingCalendar(false, createdId, [])
        
        testPromise(googleCalendar.getOurCalendar().then { calendarRef -> Void in
            /// Read from database to make sure calendar is cached
            let realm = self.realmProvider.realm()
            let calendar = realm.resolve(calendarRef)!
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
        
        testPromise(googleCalendar.getOurCalendar().then { calendarRef -> Promise<ThreadSafeReference<CalendarModel>> in
            let realm = self.realmProvider.realm()
            let calendar = realm.resolve(calendarRef)!
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
