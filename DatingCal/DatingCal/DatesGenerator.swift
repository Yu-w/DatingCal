//
//  DatesGenerator.swift
//  DatingCal
//
//  Created by Wang Yu on 4/18/17.
//
//

import Foundation

struct KeyDate {
    
    var date = ""
    var title = ""
    var desc = ""
    
    init(_ date: String, _ title: String, _ desc: String="") {
        self.date = date
        self.title = title
        self.desc = desc
    }
}

class DatesGenerator {

    init() {
        let loopKeyDates: [KeyDate] = [
            KeyDate("2/14", "Valentine‘s Day"),
            KeyDate("3/14", "White Day"),
            KeyDate("7/7", "Double Seventh Festival"),
        ]
        
        
    }
    
}
