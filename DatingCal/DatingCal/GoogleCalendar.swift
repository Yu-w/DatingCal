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
    let realmProvider : AbstractRealmProvider
    let kNameOfOurCalendar = "DatingCal calendar";
    
    init(_ client: AbstractHTTPClient, _ realmProvider: AbstractRealmProvider) {
        self.client = client
        self.realmProvider = realmProvider
    }
    
    private func listCalendarLists() -> Promise<JSON> {
        return client.request("https://www.googleapis.com/calendar/v3/users/me/calendarList", method: .get, parameters: nil).then { list -> JSON in
            // Currently, don't handle etags.
            return list["items"]
        }
    }
    
    private func listEventLists(_ calendarId: String) -> Promise<JSON> {
        let encodedId : String = calendarId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, parameters: nil).then { list -> JSON in
            // Currently, don't handle etags.
            return list["items"]
        }
    }
    
    /// Fetch and save all calendar lists. This will not sync the events in the calendars.
    private func loadAllCalendars() -> Promise<Void> {
        return listCalendarLists().then { list -> Void in
            let list = list.array ?? []
            let realm = self.realmProvider.realm()
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
    private func loadAllEvents() -> Promise<Void> {
        let realm = self.realmProvider.realm()
        return when(fulfilled: realm.objects(CalendarModel.self).map { cal in
            return listEventLists(cal.id).then { list -> Void in
                let realm = self.realmProvider.realm()
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
    
    private func getOurCalendarLocally() -> CalendarModel? {
        let realm = self.realmProvider.realm()
        let ourCalendars = realm.objects(CalendarModel.self).filter({cal in
            cal.name == self.kNameOfOurCalendar
        })
        return ourCalendars.first
    }
    
    /// Get the calendar where we should all events created by DatingCal
    func getOurCalendar() -> Promise<ThreadSafeReference<CalendarModel>> {
        if let ans = getOurCalendarLocally() {
            return Promise(value: ThreadSafeReference(to: ans))
        }
        return loadAllCalendars().then {
            if let ans = self.getOurCalendarLocally() {
                return Promise(value: ThreadSafeReference(to: ans))
            }
            let result = CalendarModel()
            result.name = self.kNameOfOurCalendar;
            return self.client.request("https://www.googleapis.com/calendar/v3/calendars", method: .post, parameters: result.unParse()).then { json -> ThreadSafeReference<CalendarModel> in
                let result = CalendarModel()
                result.parse(json)
                let realm = self.realmProvider.realm()
                try! realm.write {
                    realm.add(result, update:true)
                }
                return ThreadSafeReference(to: result)
            }
        }
    }
    
    /// Create an event in the 'DatingCal' calendar
    func createEvent(_ event: EventModel) -> Promise<ThreadSafeReference<EventModel>> {
        return getOurCalendar().then { calendarRef -> Promise<JSON> in
            let realm = self.realmProvider.realm()
            let ourCalendar = realm.resolve(calendarRef)!
            let encodedId : String = ourCalendar.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let params = event.unParse()
            return self.client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .post, parameters: params)
        }.then { createdEvent -> ThreadSafeReference<EventModel> in
            // Currently, don't handle etags.
            let event = EventModel()
            event.parse(createdEvent)
            let realm = self.realmProvider.realm()
            try! realm.write {
                realm.add(event, update:true)
            }
            return ThreadSafeReference(to: event)
        }.catch { err in
            // Need to make a copy of the current event
            // to prevent threading issues
            let eventCopy = event.createCopy()
            
            let realm = self.realmProvider.realm()
            try! realm.write {
                event.shouldCreate = true
                realm.add(event, update:true)
            }
            NetworkMonitor.shared.handleNoInternet {
                self.createEvent(eventCopy).asVoid()
            }
        }
    }
}
