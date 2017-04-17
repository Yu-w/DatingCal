//
//  GoogleError.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import Foundation
import SwiftyJSON

enum GoogleError : Error{
    case ErrorInJson(JSON)
    case NotLoggedIn
}
