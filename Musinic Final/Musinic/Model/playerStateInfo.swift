//
//  StatePark.swift
//  ParkFinder
//
//  Created by Student on 3/21/19.
//  Copyright © 2019 Student. All rights reserved.
//

import Foundation

public class playerStateInfo: NSObject {
    
    
    private var isPaused: Bool
    private var uri: String
    private var name: String
    private var imageIdentifier: String
    private var artistName: String
    private var albumName: String
    private var isSaved: Bool
    private var speed: Float
    private var isShuffling: Bool
    private var repeatMode: Int
    private var Position: Int

    
    init(isPaused: Bool, uri: String, name: String, imageIdentifier: String, artistName: String, albumName: String, isSaved: Bool, speed: Float, isShuffling: Bool, repeatMode: Int, Position: Int){
        self.isPaused = isPaused
        self.uri = uri
        self.name = name
        self.imageIdentifier = imageIdentifier
        self.artistName = artistName
        self.albumName = albumName
        self.isSaved = isSaved
        self.speed = speed
        self.isShuffling = isShuffling
        self.repeatMode = repeatMode
        self.Position = Position
        
    }
    func getName() -> String {
        return self.name
    }
    func getPaused() -> Bool {
        return self.isPaused
    }
    func getShuffling() -> Bool {
        return self.isShuffling
    }
    func getRepeat() -> Int {
        return self.repeatMode
    }
    func getimageIdentifier() -> String{
        return self.imageIdentifier
    }
    func getPosition() -> Int {
        return self.Position
    }
    
    public override var description: String{
        return "\(name) : (\(artistName),\(albumName),\(uri),\(isPaused),\(imageIdentifier),\(isSaved),\(speed),\(isShuffling),\(repeatMode),\(Position))"
    }
}
