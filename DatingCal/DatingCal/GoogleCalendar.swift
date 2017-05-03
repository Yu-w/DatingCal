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

typealias ThreadSafeCalendar = ThreadSafeReference<CalendarModel>
typealias ThreadSafeEvent = ThreadSafeReference<EventModel>

/// This is a HTTP client for Google Calendar API
/// Currently, the official API doesn't work well with Swift 3
class GoogleCalendar {
    
    let client: AbstractHTTPClient
    let realmProvider : AbstractRealmProvider
    
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
    
    /// Fetch list of events from the calendar with specified id.
    /// :param pageToken: If nil, fetch all pages. 
    ///     Otherwise, fetch everything IN&AFTER this page.
    func listEventLists(_ calendarId: String, _ pageToken: String?=nil) -> Promise<[JSON]> {
        let encodedId : String = calendarId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = "https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events"
        var params : Parameters = [:]
        if let pageToken = pageToken {
            params["pageToken"] = pageToken
        }
        return client.request(url, method: .get, parameters: params).then { list -> Promise<[JSON]> in
            // Currently, don't handle etags.
            var currAns = list["items"].array ?? []
            guard let nextPage = list["nextPageToken"].string else {
                return Promise(value: currAns)
            }
            return self.listEventLists(calendarId, nextPage).then { moreEvents -> [JSON] in
                currAns.append(contentsOf: moreEvents)
                return currAns
            }
        }
    }
    
    /// Fetch and save all calendar lists. This will not sync the events in the calendars.
    private func loadAllCalendars() -> Promise<Void> {
        return listCalendarLists().then { list -> Void in
            let list = list.array ?? []
            let realm = self.realmProvider.realm()
            let currUser = UserModel.getPrimaryUser(self.realmProvider)!
            
            for cal in realm.objects(CalendarModel.self) {
                if !list.contains(where: {$0["id"].string==cal.id}),
                    cal.owner.contains(where: {$0.id==currUser.id}) {
                    try! realm.write {
                        realm.delete(cal)
                    }
                }
            }
            
            for cal in list {
                let parsed = CalendarModel()
                parsed.parse(cal, self.realmProvider)
                try! realm.write {
                    realm.add(parsed, update: true)
                }
                
                parsed.addToPrimaryUser(self.realmProvider)
            }
        }
    }
    
    /// Fetch and save all events. This will not sync new calendars.
    private func loadAllEvents() -> Promise<Void> {
        let realm = self.realmProvider.realm()
        return when(fulfilled: realm.objects(CalendarModel.self).filter{ cal in
            let currUser = UserModel.getPrimaryUser(self.realmProvider)!
            return cal.owner.contains(where: {$0.id==currUser.id})
        }.map { cal in
            return listEventLists(cal.id).then { list -> Void in
                let realm = self.realmProvider.realm()
                for event in list {
                    let parsed = EventModel()
                    parsed.parse(event, self.realmProvider)
                    try! realm.write {
                        realm.add(parsed, update: true)
                        if !cal.events.contains(where: {x in x.id==parsed.id}) {
                            cal.events.append(parsed)
                        }
                    }
                }
            }
        })
    }
    
    /// Create the "DatingCal" calendar where we should all events created by DatingCal
    ///   Calling this function twice will create duplicate calendars.
    ///   This is a private helper function. Call ensureOurCalendar() instead.
    private func createOurCalendar() -> Promise<ThreadSafeCalendar> {
        let result = CalendarModel()
        result.name = kNameOfOurCalendar;
        return self.client.request("https://www.googleapis.com/calendar/v3/calendars", method: .post, parameters: result.unParse()).then { json -> ThreadSafeCalendar in
            let result = CalendarModel()
            result.parse(json, self.realmProvider)
            let realm = self.realmProvider.realm()
            try! realm.write {
                realm.add(result, update:true)
            }
            return ThreadSafeReference(to: result)
        }
    }
    
    /// Fetch and save all calendars and events.
    func loadAll() -> Promise<Void> {
        return loadAllCalendars().then { x in
            return self.ensureOurCalendar()
        }.then { x in
            return self.loadAllEvents()
        }
    }
    
    /// Get the "DatingCal" calendar where we should all events created by DatingCal
    func ensureOurCalendar() -> Promise<Void> {
        return firstly { _ -> Promise<ThreadSafeCalendar> in
            if let ans = CalendarModel.getPrimary(self.realmProvider) {
                return Promise(value: ThreadSafeReference(to: ans))
            }
            return loadAllCalendars().then {
                if let ans = CalendarModel.getPrimary(self.realmProvider) {
                    return Promise(value: ThreadSafeReference(to: ans))
                }
                return self.createOurCalendar()
            }
        }.then { ans -> ThreadSafeCalendar in
            let realm = self.realmProvider.realm()
            let calendar = realm.resolve(ans)!
            calendar.addToPrimaryUser(self.realmProvider)
            return ThreadSafeReference(to: calendar)
        }.asVoid()
    }
    
    /// Create any kind of event in the 'DatingCal' calendar
    func createEvent(_ event: EventModel) -> Promise<ThreadSafeEvent> {
        return ensureOurCalendar().then { _ -> Promise<JSON> in
            /// Send requests to Google
            let ourCalendar = CalendarModel.getPrimary(self.realmProvider)!
            let encodedId : String = ourCalendar.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let params = event.unParse()
            return self.client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .post, parameters: params)
        }.then { createdEvent -> ThreadSafeEvent in
            /// If successful, we store the results in DB.
            let event = EventModel()
            let ourCalendar = CalendarModel.getPrimary(self.realmProvider)!
            event.parse(createdEvent, self.realmProvider)
            let realm = self.realmProvider.realm()
            try! realm.write {
                realm.add(event, update:true)
                if !ourCalendar.events.contains(where: {x in x.id==event.id}) {
                    ourCalendar.events.append(event)
                }
            }
            return ThreadSafeReference(to: event)
        }.catch { err -> Void in
            /// Handle errors, especially if it's due to
            ///     Intenet connection issues
            
            // Need to make a copy of the current event
            // to prevent threading issues
            let eventCopy = event.createCopy(self.realmProvider)
            let isInternetProblem = NetworkMonitor.shared.handleNoInternet {
                self.createEvent(eventCopy).asVoid()
            }
            if isInternetProblem {
                let realm = self.realmProvider.realm()
                try! realm.write {
                    event.shouldCreate = true
                    realm.add(event, update:true)
                }
            }
        }
    }
    
    /// Delete an event
    /// It will throw an error if this event doesn't belong to the primary user.
    /// Please note that, once the event is deleted, all access to it will cause a crash.
    func deleteEvent(_ event: EventModel) -> Promise<Void> {
        if event.shouldCreate {
            return Promise(value: ())
        }
        guard let calendar = event.calendar.first else {
            return Promise(error: GoogleError.IncorrectUser)
        }
        guard let primaryUser = UserModel.getPrimaryUser(self.realmProvider) else {
            return Promise(error: GoogleError.NotLoggedIn)
        }
        if !calendar.owner.contains{$0.id == primaryUser.id} {
            return Promise(error: GoogleError.IncorrectUser)
        }
        let calendarId = calendar.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let eventId = event.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return self.client.request("https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events/\(eventId)", method: .delete, parameters: nil).then { _ -> Void in
            let realm = self.realmProvider.realm()
            let safeReference = realm.objects(EventModel.self).filter{$0.id==event.id}
            try! realm.write {
                realm.delete(safeReference)
            }
        }
    }
}
