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

extension GoogleError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .ErrorInJson(let json):
            return NSLocalizedString(json.rawString() ?? "Unknown error.", comment: "Error sent from Google")
        case .NotLoggedIn:
            return NSLocalizedString("You are not logged in!", comment: "Error")
        }
    }
}
