//
//  CalendarModel.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/10/17.
//
//

import Foundation

struct CalendarModel {
    var id: String
    var name: String
    var timeZone: String
    var bgColor: String
    var isPrimary: Bool
    
    static func parse(_ json: AnyObject) -> CalendarModel {
        return CalendarModel(
            id : jsonGet(json, "id")! as! String,
            name : jsonGet(json, "summary")! as! String,
            timeZone : jsonGet(json, "timeZone")! as! String,
            bgColor : jsonGet(json, "backgroundColor")! as! String,
            isPrimary : ((jsonGet(json, "primary") as? Bool) ?? false)
        )
    }
}

struct EventModel {
    var id: String
    var summary: String
    var description: String
    
    static func parse(_ json: AnyObject) -> EventModel {
        return EventModel(
            id : jsonGet(json, "id")! as! String,
            summary : jsonGet(json, "summary")! as! String,
            description : jsonGet(json, "description") as? String ?? ""
        )
    }
}
