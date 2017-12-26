//
//  HousingModel.swift
//  Housing
//
//  Created by denkeni on 04/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import Foundation

struct HousingModel : Codable {

    let 鄉鎮市區 : String?
    let 交易標的 : String?
    let 土地區段位置或建物區門牌 : String?
    let 土地移轉總面積平方公尺 : Float?
    let 都市土地使用分區 : String?
    let 非都市土地使用分區 : String?
    let 非都市土地使用編定 : String?
    let 交易年月日 : TimeInterval?
    let 交易筆棟數 : String?
    let 移轉層次 : String?
    let 總樓層數 : String?
    let 建物型態 : String?
    let 主要用途 : String?
    let 主要建材 : String?
    let 建築完成年月 : TimeInterval?
    let 建物移轉總面積平方公尺 : Float?
    let 建物現況格局_房 : Int?
    let 建物現況格局_廳 : Int?
    let 建物現況格局_衛 : Int?
    let 建物現況格局_隔間 : String?
    let 有無管理組織 : String?
    let 總價元 : Float?
    let 單價每平方公尺 : Float?
    let 車位類別 : String?
    let 車位移轉總面積平方公尺 : Float?
    let 車位總價元 : Float?
    let 備註 : String?
    let 編號 : String?
}
