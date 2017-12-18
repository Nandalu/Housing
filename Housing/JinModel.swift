//
//  JinModel.swift
//  Housing
//
//  Created by denkeni on 01/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import Foundation
import MapKit

struct JinModel : Codable {
    let Msgs : [MsgModel]
    struct MsgModel : Codable {
        let ID : String
        let Time : TimeInterval
        let Body : String
        let Lat : CLLocationDegrees
        let Lng : CLLocationDegrees
        let IsDeleted : Bool
        let SKF64 : Float
        let User : UserModel
        let App : AppModel
        struct UserModel : Codable {
            let ID : String
            let Name : String
            let Picture : String
            let ThirdPartyID : String
            let Privacy : String
        }
        struct AppModel : Codable {
            let ID : String
            let Name : String
            let Icon : String
            let MarketingURI : String
        }
    }
}
