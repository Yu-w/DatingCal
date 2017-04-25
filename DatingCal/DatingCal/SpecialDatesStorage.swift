//
//  SpecialDatesStorage.swift
//  DatingCal
//
//  Created by Wang Yu on 4/24/17.
//
//

import UIKit
import RealmSwift

class SpecialDatesStorage: Object {

    dynamic var id = 0
    let dates = List<EventModel>()
    
    override static func primaryKey() -> String? {
        return "id"
    }

}
