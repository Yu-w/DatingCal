//
//  CalendarModel.swift
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

class CalendarModel : Object, GoogleParsable {

    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var timeZone: String? = nil
    dynamic var bgColor: String? = nil
    dynamic var isPrimary: Bool = false
    var events = List<EventModel>()
    
    let owner = LinkingObjects(fromType: UserModel.self, property: "calendars")
    
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
    func parse(_ json: JSON, _ realmProvider: AbstractRealmProvider) {
        let originalId = id
        id = json["id"].string!
        name = json["summary"].string!
        timeZone = json["timeZone"].string
        bgColor = json["backgroundColor"].string
        isPrimary = json["primary"].bool ?? false
        if originalId != id {
            let realm = realmProvider.realm()
            let newCalendar = realm.objects(CalendarModel.self).filter{x in x.id==self.id}.first
            events = newCalendar?.events ?? List<EventModel>()
        }
    }
}
