//
//  CalendarModel.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/10/17.
//
//

import Foundation
import SwiftyJSON
import RealmSwift
import SwiftDate

class CalendarModel : Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var timeZone: String? = nil
    dynamic var bgColor: String? = nil
    dynamic var isPrimary: Bool = false
    let events = List<EventModel>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    /// Create a CalendarModel from a JSON returned from Google
    static func parse(_ json: JSON) -> CalendarModel {
        var ans = CalendarModel()
        ans.id = json["id"].string!
        ans.name = json["summary"].string!
        ans.timeZone = json["timeZone"].string
        ans.bgColor = json["backgroundColor"].string
        ans.isPrimary = json["primary"].bool ?? false
        return ans
    }
}

class EventModel : Object {
    dynamic var id: String = ""
    dynamic var summary: String = ""
    dynamic var desc: String = ""
    dynamic var startDate: Date? = nil
    dynamic var startTime: Date? = nil
    dynamic var startTimeZone: String? = nil
    dynamic var endDate: Date? = nil
    dynamic var endTime: Date? = nil
    dynamic var endTimeZone: String? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    /// A helper function that parses any substructure that represents a time/date
    ///   json: Please pass in the substructure that directly contains "dateTime" or "date"
    private static func parseDates(_ json: JSON) -> (Date?, Date?, String?) {
        var date : Date? = nil
        var time : Date? = nil
        var timeZone : String? = nil
        if let startTime = json["dateTime"].string {
            time = ISO8601Parser.date(from: startTime)?.date
            timeZone = json["timeZone"].string
        }
        if let startDate = json["date"].string {
            var dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.date(from: startDate)
        }
        return (date, time, timeZone)
    }
    
    /// Create a EventModel from a JSON returned from Google
    static func parse(_ json: JSON) -> EventModel {
        var ans = EventModel()
        let start = parseDates(json["start"])
        let end = parseDates(json["end"])
        ans.id = json["id"].string!
        ans.summary = json["summary"].string!
        ans.desc = json["description"].string ?? ""
        ans.startDate = start.0
        ans.startTime = start.1
        ans.startTimeZone = start.2
        ans.endDate = end.0
        ans.endTime = end.1
        ans.endTimeZone = end.2
        return ans
    }
}
