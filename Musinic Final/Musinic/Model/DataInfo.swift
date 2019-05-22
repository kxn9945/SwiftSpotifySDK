//
//  DataInfo.swift
//  Musinic
//
//  Created by Student on 5/1/19.
//  Copyright © 2019 Student. All rights reserved.
//

import Foundation

class DataInfo {
    static let shared = DataInfo()
    
    var data = [ITunesTrack]()
    var songName = ""
    var songID = ""
    
    private init(){
        print("Created ITunesTrackData instance")
    }
}
