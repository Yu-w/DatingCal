//
//  AbstractModels.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/25/17.
//
//

import Foundation
import SwiftyJSON
import RealmSwift
import SwiftDate
import Alamofire

protocol GoogleParsable {
    /// Parse and update this model object
    ///    with a json from Google.
    /// NOTE: If the id in json is NOT the id of
    ///    the current object, and if your subclass
    ///    includes internal states not fetched from Google,
    ///    then this should create a new model with
    ///    with a new set of internal states, and
    ///    should not interfere with the old model.
    func parse(_ json: JSON, _ realmProvider: AbstractRealmProvider)
    
    /// Turn this model object into a 'Parameters'
    ///    dictionary whose key names comply with Google
    ///    API's standard.
    /// NOTE: If your subclass includes internal
    ///    states which were not fetched from Google,
    ///    then the result should not include internal states.
    func unParse() -> Parameters
}
