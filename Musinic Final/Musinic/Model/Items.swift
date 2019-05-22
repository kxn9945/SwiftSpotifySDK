//
//  Items.swift
//  Musinic
//
//  Created by Student on 5/2/19.
//  Copyright © 2019 Student. All rights reserved.
//

import Foundation
class Items : Codable {
    var popularity:Int?
    var album: Album?
    var artists: [Artists]?
    var duration_ms:Int?
    var id:String?
    var name:String?
    
}
