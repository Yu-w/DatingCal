//
//  Configurations.swift
//  DatingCal
//
//  Created by Wang Yu on 4/18/17.
//
//

import Foundation

class Configurations: Defaults {
    
    static let sharedInstance = Configurations()
    
    dynamic var needOnboard = true
    dynamic var currentIdString = ""
    dynamic var birthDate = [String: Date]()
    dynamic var relationshipDate = [String: Date]()
    
    func currentId() -> String? {
        return Configurations.sharedInstance.currentIdString == ""
            ? nil
            : Configurations.sharedInstance.currentIdString
    }
    
    func birthDate(id: String=Configurations.sharedInstance.currentId()!) -> Date? {
        return Configurations.sharedInstance.birthDate[id]
    }
    
    func relationshipDate(id: String=Configurations.sharedInstance.currentId()!) -> Date? {
        return Configurations.sharedInstance.relationshipDate[id]
    }
    
    func setBirthDate(date: Date) {
        Configurations.sharedInstance.birthDate[Configurations.sharedInstance.currentId()!] = date
    }
    
    func setRelationshipDate(date: Date) {
        Configurations.sharedInstance.relationshipDate[Configurations.sharedInstance.currentId()!] = date
    }
}
