//
//  CalendarModel.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/10/17.
//
//

import Foundation
import SwiftyJSON

struct CalendarModel {
    var id: String
    var name: String
    var timeZone: String
    var bgColor: String
    var isPrimary: Bool
    
    static func parse(_ json: JSON) -> CalendarModel {
        return CalendarModel(
            id : json["id"].string!,
            name : json["summary"].string!,
            timeZone : json["timezone"].string!,
            bgColor : json["backgroundColor"].string!,
            isPrimary : json["primary"].bool ?? false
        )
    }
}

struct EventModel {
    var id: String
    var summary: String
    var description: String
    
    static func parse(_ json: JSON) -> EventModel {
        return EventModel(
            id : json["id"].string!,
            summary : json["summary"].string!,
            description : json["description"].string ?? ""
        )
    }
}
