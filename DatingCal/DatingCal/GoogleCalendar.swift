//
//  CalendarApi.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/10/17.
//
//

import Foundation
import PromiseKit
import Alamofire
import SwiftyJSON
import RealmSwift

/// This is a HTTP client for Google Calendar API
/// Currently, the official API doesn't work well with Swift 3
class GoogleCalendar {
    
    let client: AbstractHTTPClient
    
    init(_ client: AbstractHTTPClient) {
        self.client = client
    }
    
    func listCalendarLists() -> Promise<JSON> {
        return client.request("https://www.googleapis.com/calendar/v3/users/me/calendarList", method: .get, parameters: nil).then { list -> JSON in
            // Currently, don't handle etags.
            return list["items"]
        }
    }
    
    func listEventLists(_ calendarId: String) -> Promise<JSON> {
        let encodedId : String = calendarId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, parameters: nil).then { list -> JSON in
            // Currently, don't handle etags.
            return list["items"]
        }
    }
    
    /// Fetch and save all calendar lists. This will not sync the events in the calendars.
    func loadAllCalendars() -> Promise<Void> {
        return listCalendarLists().then { list -> Void in
            let list = list.array ?? []
            let realm = try! Realm()
            let listAsSet = NSMutableSet(array: list)
            
            for cal in realm.objects(CalendarModel.self) {
                if !listAsSet.contains(cal) {
                    try! realm.write {
                        realm.delete(cal)
                    }
                }
            }
            
            for cal in list {
                let parsed = CalendarModel()
                parsed.parse(cal)
                try! realm.write {
                    realm.add(parsed, update: true)
                }
            }
        }
    }
    
    /// Fetch and save all events. This will not sync new calendars.
    func loadAllEvents() -> Promise<Void> {
        let realm = try! Realm()
        return when(fulfilled: realm.objects(CalendarModel.self).map { cal in
            return listEventLists(cal.id).then { list -> Void in
                var realm = try! Realm()
                for event in (list.array ?? []) {
                    let parsed = EventModel()
                    parsed.parse(event)
                    try! realm.write {
                        realm.add(parsed, update: true)
                        cal.events.append(parsed)
                    }
                }
            }
        })
    }
    
    /// Fetch and save all calendars and events.
    func loadAll() -> Promise<Void> {
        return loadAllCalendars().then { x in
            return self.loadAllEvents()
        }
    }
    
    func createEvent(_ event: EventModel, _ inCalendar: CalendarModel) -> Promise<Void> {
        let encodedId : String = inCalendar.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let params = event.unParse()
        return client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, parameters: params).then { createdEvent -> Void in
            // Currently, don't handle etags.
            event.parse(createdEvent)
            let realm = try! Realm()
            try! realm.write {
                realm.add(event, update:true)
            }
        }
    }
}
