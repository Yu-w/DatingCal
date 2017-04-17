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
import Alamofire

protocol GoogleParsable {
    func parse(_ json: JSON)
    func unParse() -> Parameters
}

class CalendarModel : Object, GoogleParsable {

    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var timeZone: String? = nil
    dynamic var bgColor: String? = nil
    dynamic var isPrimary: Bool = false
    var events = List<EventModel>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func unParse() -> Parameters {
        var ans : Parameters = [:]
        ans["summary"] = name
        ans["timeZone"] = timeZone
        return ans
    }
    
    /// Create a CalendarModel from a JSON returned from Google
    func parse(_ json: JSON) {
        let originalId = id
        id = json["id"].string!
        name = json["summary"].string!
        timeZone = json["timeZone"].string
        bgColor = json["backgroundColor"].string
        isPrimary = json["primary"].bool ?? false
        if originalId != id {
            events = List<EventModel>()
        }
    }
}

class EventModel : Object, GoogleParsable {
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
    private func parseDates(_ json: JSON) -> (Date?, Date?, String?) {
        var date : Date? = nil
        var time : Date? = nil
        var timeZone : String? = nil
        if let startTime = json["dateTime"].string {
            time = ISO8601Parser.date(from: startTime)?.date
            timeZone = json["timeZone"].string
        }
        if let startDate = json["date"].string {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.date(from: startDate)
        }
        return (date, time, timeZone)
    }
    
    private func unParseDates(_ date: Date?, _ time: Date?, _ timeZone: String?) -> Parameters {
        var ans : Parameters = [:]
        ans["date"] = date?.string(format: DateFormat.custom("yyyy-MM-dd"))
        ans["timeZone"] = timeZone
        
        if let time = time {
            let dateTimeFormat = ISO8601DateFormatter()
            if let timeZone = timeZone {
                dateTimeFormat.timeZone = TimeZone(identifier: timeZone)
            }
            ans["dateTime"] = dateTimeFormat.string(from: time)
        }
        return ans
    }
    
    func unParse() -> Parameters {
        var ans : Parameters = [:]
        let startDict : Parameters = unParseDates(startDate, startTime, startTimeZone)
        let endDict : Parameters = unParseDates(endDate, endTime, endTimeZone)
        ans["summary"] = summary
        ans["description"] = desc
        ans["start"] = startDict
        ans["end"] = endDict
        return ans
    }
    
    /// Create a EventModel from a JSON returned from Google
    func parse(_ json: JSON) {
        let start = parseDates(json["start"])
        let end = parseDates(json["end"])
        id = json["id"].string!
        summary = json["summary"].string ?? ""
        desc = json["description"].string ?? ""
        startDate = start.0
        startTime = start.1
        startTimeZone = start.2
        endDate = end.0
        endTime = end.1
        endTimeZone = end.2
    }
}
