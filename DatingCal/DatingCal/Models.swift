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
    /// Parse and update this model object
    ///    with a json from Google.
    /// NOTE: If the id in json is NOT the id of
    ///    the current object, and if your subclass
    ///    includes internal states not fetched from Google,
    ///    then this should create a new model with
    ///    with a new set of internal states, and
    ///    should not interfere with the old model.
    func parse(_ json: JSON)
    
    /// Turn this model object into a 'Parameters'
    ///    dictionary whose key names comply with Google
    ///    API's standard.
    /// NOTE: If your subclass includes internal
    ///    states which were not fetched from Google,
    ///    then the result should not include internal states.
    func unParse() -> Parameters
}

class UserModel : Object, GoogleParsable {
    dynamic var id: String = ""
    dynamic var name: String = ""
    
    /// This is an internal state that links
    ///   to this user's "DatingCal" calendar
    dynamic var datingCalendar: CalendarModel?
    
    /// This is an internal state that links
    ///   to any calendar owned by this person
    ///   "DatingCal" must also be included.
    var calendars = List<CalendarModel>()
    
    /// This is a "GET-only" state
    private dynamic var _email: String = ""
    var email : String {
        get {
            return _email
        }
    }
    
    /// This is an internal state of our app
    ///  External classes should not change its value.
    dynamic var _isPrimary: Bool = false
    var isPrimary : Bool {
        get {
            return _isPrimary
        }
    }
    
    /// Path to a file in local storage.
    /// This file contains serialized authorization 
    ///     tokens for this user.
    var authStorage : String {
        get {
            let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return library + "/google-auth-" + id + ".dat"
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    /// Remove "self" from DB and delete its TOKENS from hard drive
    func remove(_ realmProvider: AbstractRealmProvider) {
        try? FileManager.default.removeItem(atPath: authStorage)
        let realm = realmProvider.realm()
        let userInDB = realm.objects(UserModel.self).filter({x in x.id==self.id}).first
        guard let user = userInDB else {
            return
        }
        try? realm.write {
            for cal in user.calendars {
                realm.delete(cal.events)
                realm.delete(cal)
            }
            realm.delete(user)
            let primaryUser = realm.objects(UserModel.self).filter({x in x._isPrimary}).first
            if primaryUser == nil, let first = realm.objects(UserModel.self).first {
                first._isPrimary = true
            }
        }
    }
    
    /// This variable always returns the primary user.
    static func getPrimaryUser(_ realmProvider: AbstractRealmProvider) -> UserModel? {
        let realm = realmProvider.realm()
        let primary = realm.objects(UserModel.self).filter({u in u.isPrimary}).first
        return primary
    }
    
    func setPrimaryUser(_ realmProvider: AbstractRealmProvider) {
        let realm = realmProvider.realm()
        let primaryUser = realm.objects(UserModel.self).filter({x in x._isPrimary})
        try? realm.write {
            primaryUser.forEach {x in x._isPrimary = false}
            self._isPrimary = true
        }
    }
    
    func parse(_ json: JSON) {
        let originalId = id
        id = json["id"].string!
        name = json["displayName"].string!
        _email = parseEmail(json)
        if originalId != id {
            _isPrimary = false
            datingCalendar = nil
            calendars = List<CalendarModel>()
        }
    }
    
    func unParse() -> Parameters {
        var ans : Parameters = [:]
        ans["displayName"] = name
        return ans
    }
    
    private func parseEmail(_ json: JSON) -> String {
        guard let emails = json["emails"].array else {
            return ""
        }
        for email in emails {
            guard let value = email["value"].string else {
                continue
            }
            guard let type = email["type"].string else {
                continue
            }
            if type == "account" {
                return value
            }
        }
        return ""
    }
}

class CalendarModel : Object, GoogleParsable {

    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var timeZone: String? = nil
    dynamic var bgColor: String? = nil
    dynamic var isPrimary: Bool = false
    var events = List<EventModel>()
    
    let owner = LinkingObjects(fromType: UserModel.self, property: "datingCalendar")
    
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
    dynamic var keyDateType: String? = nil
    private dynamic var _recurrence: String? = nil
    
    let calendar = LinkingObjects(fromType: CalendarModel.self, property: "events")
    
    /// This indicates whether the event should be
    ///    sent to Google again, because it's not
    ///    created in upstream yet.
    dynamic var shouldCreate: Bool = false
    
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
    func parse(_ json: JSON) {
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
            shouldCreate = false
        }
    }
    
    /// Create a copy of this object which is not thread-confined.
    func createCopy() -> EventModel {
        let ans = EventModel()
        var params = unParse()
        params["id"] = ""
        ans.parse(JSON(params))
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
