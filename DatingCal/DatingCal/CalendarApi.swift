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
                } else {
                    fulfill(response.value!)
                }
            })
        }
    }
    
    func listCalendarLists() -> Promise<Any> {
        return requestPromise(Alamofire.request("https://www.googleapis.com/calendar/v3/users/me/calendarList", method: .get, headers: getHeaders())).then { list in
            // Currently, don't handle etags.
            return list.items
        }
    }
}
