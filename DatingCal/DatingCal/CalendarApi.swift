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

enum GoogleError : Error{
    case ErrorInJson(JSON)
}

/// This is a HTTP client for Google Calendar API
/// Currently, the official API doesn't work well with Swift 3
class GoogleCalendar {
    
    var accessToken : String
    
    /// accessToken: the authorization token for this user, returned by Google OAuth2 protocol
    init(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    func getHeaders() -> HTTPHeaders {
        return ["Authorization":"Bearer " + accessToken]
    }
    
    /// Wrap any Alamofire request in a Promise
    /// (PromiseKit/Alamofire- isn't working...)
    func requestPromise(_ request: DataRequest) -> Promise<JSON> {
        return Promise {fulfill, reject in
            request.responseJSON(completionHandler: { response in
                if let err = response.error {
                    reject(err)
                } else if let data = response.data {
                    let json = JSON(data: data)
                    if let error = json.dictionary?["error"] {
                        reject(GoogleError.ErrorInJson(error))
                    } else {
                        fulfill(json)
                    }
                }
            })
        }
    }
    
    func listCalendarLists() -> Promise<JSON> {
        return requestPromise(request("https://www.googleapis.com/calendar/v3/users/me/calendarList", method: .get, headers: getHeaders())).then { list -> JSON in
            // Currently, don't handle etags.
            return list["items"]
        }
    }
    
    func listEventLists(_ calendarId: String) -> Promise<JSON> {
        let encodedId : String = calendarId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return requestPromise(request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, headers: getHeaders())).then { list -> JSON in
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
        return requestPromise(request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, parameters: params, encoding: JSONEncoding.default, headers: getHeaders())).then { createdEvent -> Void in
            // Currently, don't handle etags.
            event.parse(createdEvent)
            let realm = try! Realm()
            try! realm.write {
                realm.add(event, update:true)
            }
        }
    }
}
