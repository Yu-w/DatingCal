//
//  KeyDate.swift
//  DatingCal
//
//  Created by Wang Yu on 4/24/17.
//
//

import Foundation

struct KeyDate {
    
    var date: Date
    var title: String
    var desc: String
    var recurrence: [String]?
    var keyDateType: String?
    
    /// A possible value for the parameter "recurrence" in our constructors
    public static var yearly = ["RRULE:FREQ=YEARLY"]
    
    init(date: Date, recurrence: [String]?=nil, _ title: String, _ desc: String="") {
        self.date = date
        self.title = title
        self.desc = desc
        self.recurrence = recurrence
    }
    
    init(month: Int, day: Int, recurrence: [String]?=nil, _ title: String, _ desc: String="") {
        var c = DateComponents()
        c.year = Date().year
        c.month = month
        c.day = day
        self.date = Calendar(identifier: Calendar.Identifier.gregorian).date(from: c)!
        self.title = title
        self.desc = desc
        self.recurrence = recurrence
    }
    
    func addKeyDateType(type: String) -> KeyDate {
        var copy = self
        copy.keyDateType = type
        return copy
    }
    
    func addKeyDateTypeWithTitle() -> KeyDate {
        var copy = self
        copy.keyDateType = self.title
        return copy
    }
    
}

extension KeyDate {
    
    func toEventModel() -> EventModel {
        let e = EventModel()
        e.startDate = self.date
        e.endDate = self.date
        e.summary = self.title
        e.desc = self.desc
        e.setRecurrence(newValue: recurrence)
        e.keyDateType = self.keyDateType
        return e
    }
}
