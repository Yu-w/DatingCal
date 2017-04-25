//
//  DatesGenerator.swift
//  DatingCal
//
//  Created by Wang Yu on 4/18/17.
//
//

import Foundation
import SwiftDate

class DatesGenerator {

    static let sharedInstance = DatesGenerator()
    
    func generateDates(birthDate: Date, relationshipDate: Date) -> [EventModel] {
        let datesToAdd: [KeyDate] = [
            // Yearly events:
            KeyDate(month: 2, day: 14, recurrence: KeyDate.yearly, "Valentine‘s Day"),
            KeyDate(month: 3, day: 14, recurrence: KeyDate.yearly, "White Day"),
            KeyDate(month: 7, day: 7, recurrence: KeyDate.yearly, "Double Seventh Festival"),
            KeyDate(month: 3, day: 8, recurrence: KeyDate.yearly, "Women's Day"),
            KeyDate(date: birthDate, recurrence: KeyDate.yearly, "Your Love Ones' birthday"),
            
            // Events that do not come EVERY year:
            KeyDate(date: relationshipDate, "Your relationship anniversary"),
            KeyDate(date: relationshipDate + 1.month, "One month from determining the relationship"),
            KeyDate(date: relationshipDate + 50.days, "50th day from determining the relationship"),
            KeyDate(date: relationshipDate + 100.days, "100th day from determining the relationship"),
            KeyDate(date: relationshipDate + 1000.days, "A thousand days from determining the relationship")
        ]
        return datesToAdd.map { x in x.toEventModel() }
    }
    
}

