//
//  UserModel.swift
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
        if primary != nil {
            return primary
        }
        let user = realm.objects(UserModel.self).first
        try! realm.write {
            user?._isPrimary = true
        }
        return user
    }
    
    func setPrimaryUser(_ realmProvider: AbstractRealmProvider) {
        let realm = realmProvider.realm()
        let primaryUser = realm.objects(UserModel.self).filter({x in x._isPrimary})
        try? realm.write {
            primaryUser.forEach {x in x._isPrimary = false}
            self._isPrimary = true
        }
    }
    
    func parse(_ json: JSON, _ realmProvider: AbstractRealmProvider) {
        let originalId = id
        id = json["id"].string!
        name = json["displayName"].string!
        _email = parseEmail(json)
        if originalId != id {
            let realm = realmProvider.realm()
            let newUser = realm.objects(UserModel.self).filter{x in x.id==self.id}.first
            _isPrimary = newUser?._isPrimary ?? false
            datingCalendar = newUser?.datingCalendar ?? nil
            calendars = newUser?.calendars ?? List<CalendarModel>()
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
