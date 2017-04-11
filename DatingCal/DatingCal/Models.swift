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

class CalendarModel : Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var timeZone: String = ""
    dynamic var bgColor: String = ""
    dynamic var isPrimary: Bool = false
    
    static func parse(_ json: JSON) -> CalendarModel {
        var ans = CalendarModel()
        ans.id = json["id"].string!
        ans.name = json["summary"].string!
        ans.timeZone = json["timeZone"].string!
        ans.bgColor = json["backgroundColor"].string!
        ans.isPrimary = json["primary"].bool ?? false
        return ans
    }
}

class EventModel : Object {
    dynamic var id: String = ""
    dynamic var summary: String = ""
    dynamic var desc: String = ""
    
    static func parse(_ json: JSON) -> EventModel {
        var ans = EventModel()
        ans.id = json["id"].string!
        ans.summary = json["summary"].string!
        ans.desc = json["description"].string ?? ""
        return ans
    }
}
