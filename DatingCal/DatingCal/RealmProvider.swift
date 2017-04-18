//
//  RealmProvider.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/17/17.
//
//

import Foundation
import RealmSwift

protocol AbstractRealmProvider {
    func realm() -> Realm
}

class BusinessRealmProvider : AbstractRealmProvider {
    func realm() -> Realm {
        return try! Realm()
    }
}
