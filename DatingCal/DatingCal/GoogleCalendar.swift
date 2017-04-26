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
                    let user = UserModel.getPrimaryUser(self.realmProvider)!
                    if !user.calendars.contains(where: {x in x.id==parsed.id}) {
                        user.calendars.append(parsed)
                    }
                    if parsed.name == self.kNameOfOurCalendar {
                        user.datingCalendar = parsed
                    }
                }
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
    ///   This is a private helper function. Call getOurCalendar() instead.
    private func createOurCalendar() -> Promise<ThreadSafeCalendar> {
        let result = CalendarModel()
        result.name = self.kNameOfOurCalendar;
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
            return self.getOurCalendar().asVoid()
        }.then { x in
            return self.loadAllEvents()
        }
    }
    
    private func getOurCalendarLocally() -> CalendarModel? {
        let user = UserModel.getPrimaryUser(self.realmProvider)
        return user?.datingCalendar
    }
    
    /// Get the "DatingCal" calendar where we should all events created by DatingCal
    func getOurCalendar() -> Promise<ThreadSafeCalendar> {
        return firstly { _ -> Promise<ThreadSafeCalendar> in
            if let ans = getOurCalendarLocally() {
                return Promise(value: ThreadSafeReference(to: ans))
            }
            return loadAllCalendars().then {
                if let ans = self.getOurCalendarLocally() {
                    return Promise(value: ThreadSafeReference(to: ans))
                }
                return self.createOurCalendar()
            }
        }.then { ans -> ThreadSafeCalendar in
            let realm = self.realmProvider.realm()
            let calendar = realm.resolve(ans)!
            try! realm.write {
                let user = UserModel.getPrimaryUser(self.realmProvider)!
                user.datingCalendar = calendar
                if !user.calendars.contains(where: {x in x.id==calendar.id}) {
                    user.calendars.append(calendar)
                }
            }
            return ThreadSafeReference(to: calendar)
        }
    }
    
    /// Create any kind of event in the 'DatingCal' calendar
    func createEvent(_ event: EventModel) -> Promise<ThreadSafeEvent> {
        return getOurCalendar().then { calendarRef -> Promise<JSON> in
            /// Send requests to Google
            let realm = self.realmProvider.realm()
            let ourCalendar = realm.resolve(calendarRef)!
            let encodedId : String = ourCalendar.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let params = event.unParse()
            return self.client.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .post, parameters: params)
        }.then { createdEvent -> ThreadSafeEvent in
            /// If successful, we store the results in DB.
            let event = EventModel()
            event.parse(createdEvent, self.realmProvider)
            let realm = self.realmProvider.realm()
            try! realm.write {
                realm.add(event, update:true)
            }
            return ThreadSafeReference(to: event)
        }.catch { err -> Void in
            /// Handle errors, especially if it's due to
            ///     Intenet connection issues
            
            // Need to make a copy of the current event
            // to prevent threading issues
            let eventCopy = event.createCopy(self.realmProvider)
            
            let realm = self.realmProvider.realm()
            try! realm.write {
                event.shouldCreate = true
                realm.add(event, update:true)
            }
            _ = NetworkMonitor.shared.handleNoInternet {
                self.createEvent(eventCopy).asVoid()
            }
        }
    }
}
