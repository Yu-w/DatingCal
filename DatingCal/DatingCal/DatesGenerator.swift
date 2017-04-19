//
//  DatesGenerator.swift
//  DatingCal
//
//  Created by Wang Yu on 4/18/17.
//
//

import Foundation
import SwiftDate

struct KeyDate {
    
    var date: Date
    var title: String
    var desc: String
    
    init(date: Date, _ title: String, _ desc: String="") {
        self.date = date
        self.title = title
        self.desc = desc
    }
    
    init(month: Int, day: Int, _ title: String, _ desc: String="") {
        var c = DateComponents()
        c.year = Date().year
        c.month = month
        c.day = day
        self.date = Calendar(identifier: Calendar.Identifier.gregorian).date(from: c)!
        self.title = title
        self.desc = desc
    }}

class DatesGenerator {

    static let sharedInstance = DatesGenerator()
    
    func generateDates(birthDate: Date, relationshipDate: Date) -> [EventModel] {
        let datesToExpand: [KeyDate] = [
            KeyDate(month: 2, day: 14, "Valentine‘s Day"),
            KeyDate(month: 3, day: 14, "White Day"),
            KeyDate(month: 7, day: 7, "Double Seventh Festival"),
            KeyDate(month: 3, day: 8, "Women's Day"),
            KeyDate(date: birthDate, "Your Love Ones' birthday"),
            KeyDate(date: relationshipDate, "Your relationship anniversary"),
            ]
        var datesToAdd: [KeyDate] = [
            KeyDate(date: relationshipDate + 1.month, "One month from determining the relationship"),
            KeyDate(date: relationshipDate + 50.days, "50th day from determining the relationship"),
            KeyDate(date: relationshipDate + 100.days, "100th day from determining the relationship"),
            KeyDate(date: relationshipDate + 1000.days, "A thousand days from determining the relationship")
        ]
        datesToExpand.forEach { d in
            datesToAdd.append(contentsOf: d.datesInManyYears(1)) // Currently, this will upset Google. Should use repeated events.
        }
        return datesToAdd.map { x in x.toEventModel() }
    }
    
    
}

extension KeyDate {
    
    func toEventModel() -> EventModel {
        let e = EventModel()
        e.startDate = self.date
        e.endDate = self.date
        e.summary = self.title
        e.desc = self.desc
        return e
    }
    
    func datesInManyYears(_ numYears: Int) -> [KeyDate] {
        var dates: [KeyDate] = []
        for i in 0..<numYears {
            var copy = self
            copy.date = copy.date + i.year
            dates.append(copy)
        }
        return dates
    }
    
}
