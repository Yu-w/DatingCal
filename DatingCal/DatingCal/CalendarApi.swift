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

/// Get an item from Alamofire's json dictionary using key
func jsonGet(_ json: Any, _ key: String) -> AnyObject? {
    let json = json as! [String:AnyObject]
    return json[key]
}

/// Get an item from Alamofire's json array using index
func jsonGet(_ json: Any, _ key: Int) -> AnyObject? {
    let json = json as! [AnyObject]
    return json[key]
}

/// Determine whether an Alamofire's json dictionary contains key
func jsonHas(_ json:Any, _ key: String) -> Bool {
    let json = json as! [String:AnyObject]
    return json.keys.contains(key)
}

/// Get the length of Alamofire's json array
func jsonCount(_ json: Any) -> Int {
    let json = json as! [AnyObject]
    return json.count
}

enum GoogleError : Error{
    case ErrorInJson(AnyObject)
}

/// This is a HTTP client for Google Calendar API
/// Currently, the official API doesn't work well with Swift 3
class GoogleCalendar {
    
    var accessToken : String
    
    init(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    func getHeaders() -> HTTPHeaders {
        return ["Authorization":"Bearer " + accessToken]
    }
    
    /// Wrap any Alamofire request in a Promise
    /// (PromiseKit/Alamofire- isn't working...)
    func requestPromise(_ request: DataRequest) -> Promise<Any> {
        return Promise {fulfill, reject in
            request.responseJSON(completionHandler: { response in
                if let err = response.error {
                    reject(err)
                } else if let val = response.value {
                    if let err = jsonGet(val, "error") {
                        reject(GoogleError.ErrorInJson(err))
                    } else {
                        fulfill(val)
                    }
                }
            })
        }
    }
    
    func listCalendarLists() -> Promise<AnyObject> {
        return requestPromise(Alamofire.request("https://www.googleapis.com/calendar/v3/users/me/calendarList", method: .get, headers: getHeaders())).then { list -> AnyObject in
            // Currently, don't handle etags.
            return jsonGet(list, "items")!
        }
    }
    
    func listEventLists(_ calendarId: String) -> Promise<AnyObject> {
        let encodedId : String = calendarId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return requestPromise(Alamofire.request("https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events", method: .get, headers: getHeaders())).then { list -> AnyObject in
            // Currently, don't handle etags.
            return jsonGet(list, "items")!
        }
        
    }
}
