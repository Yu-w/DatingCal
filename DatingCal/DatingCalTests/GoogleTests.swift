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
import XCTest

/// This is supposed to be used as a base class.
class GoogleTests : AsyncTests {
    
    var client = FakeHTTPClient()
    var realmProvider = FakeRealmProvider()
    
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
            /// Then, respond to 'create calendar' API
            XCTAssertNotNil(params)
            var json = JSON(params!)
            json["id"].string = createdId
            return Promise(value: json)
        }
    }
}
