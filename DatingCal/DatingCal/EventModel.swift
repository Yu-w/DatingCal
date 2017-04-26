//
//  EventModel.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/26/17.
//
//

import Foundation
import SwiftyJSON
import RealmSwift
import SwiftDate
import Alamofire

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
    private dynamic var _recurrence: String? = nil
    
    let calendar = LinkingObjects(fromType: CalendarModel.self, property: "events")
    
    /// This indicates whether the event should be
    ///    sent to Google again, because it's not
    ///    created in upstream yet.
    dynamic var shouldCreate: Bool = false
    
    /// This is an internal state added by Yu Wang
    ///    Management of the state was added by Zhongzhi.
    dynamic var keyDateType: String? = nil
    
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
        ans["recurrence"] = getRecurrence()
        return ans
    }
    
    /// Create a EventModel from a JSON returned from Google
    func parse(_ json: JSON, _ realmProvider: AbstractRealmProvider) {
        let originalId = id
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
        _recurrence = json["recurrence"].rawString()
        
        if originalId != id {
            let realm = realmProvider.realm()
            let newEvent = realm.objects(EventModel.self).filter{x in x.id==self.id}.first
            shouldCreate = newEvent?.shouldCreate ?? false
            keyDateType = newEvent?.keyDateType
        }
    }
    
    /// Create a copy of this object which is not thread-confined.
    func createCopy(_ realmProvider: AbstractRealmProvider) -> EventModel {
        let ans = EventModel()
        var params = unParse()
        params["id"] = id
        ans.parse(JSON(params), realmProvider)
        return ans
    }
    
    /// getter for a conceptual variable "recurrence: [String]?"
    /// "recurrence" is a list of rules about how the event should repeat
    ///     I can't really declare this as a var {get {}}
    ///     , because Realm will be upset
    func getRecurrence() -> [String]? {
        guard let recurrString = _recurrence else {
            return nil
        }
        guard let recurrList = JSON(parseJSON: recurrString).array else {
            return nil
        }
        var ans : [String] = []
        for rule in recurrList {
            guard let ruleStr = rule.string else {
                return nil
            }
            ans.append(ruleStr)
        }
        return ans
    }
    
    /// setter for a conceptual variable "recurrence: [String]?"
    /// "recurrence" is a list of rules about how the event should repeat
    ///     I can't really declare this as a var {set {}}
    ///     , because Realm will be upset
    func setRecurrence(newValue: [String]?) {
        guard let newValue = newValue else {
            _recurrence = nil
            return
        }
        _recurrence = JSON(newValue).rawString()
    }
    
    func isYearly() -> Bool {
        guard let recurrence = getRecurrence() else {
            return false
        }
        let regex = try! NSRegularExpression(pattern: "freq[ \\t]*=[ \\t]*yearly", options: [.caseInsensitive])
        for rule in recurrence {
            let matches = regex.matches(in: rule, options: [], range: NSRange(location: 0, length: rule.characters.count))
            if matches.count > 0 {
                return true
            }
        }
        return false
    }
    
    /// A function that helps decide whether to show an event on a given date.
    func shouldShowAtDate(_ dateToShow: Date, _ calendar: Calendar) -> Bool {
        /// These code were copied from MainCalendarViewController.swift during a refactoring (by Mark Yu).
        ///   It was originally created by Yu Wang.
        let eitherDate = startTime != nil ? startTime : startDate
        guard var date = eitherDate else {
            return false
        }
        let deltaYear = dateToShow.year - date.year
        if isYearly() && deltaYear >= 0 {
            date = date + deltaYear.year
        }
        return calendar.isDate(date, inSameDayAs: dateToShow)
    }
}
