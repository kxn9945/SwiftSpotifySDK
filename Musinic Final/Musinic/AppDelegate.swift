//
//  AppDelegate.swift
//  Musinic
//
//  Created by Student on 4/15/19.
//  Copyright © 2019 Student. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate{
    var window: UIWindow?
    
    //MARK : Attributes
    let SpotifyClientID = Constants.clientID
    let SpotifyRedirectURL = Constants.redirectURI
    //let SpotifyRedirectURL = URL(string: "Musinic://")!
    
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyClientID,
        redirectURL: SpotifyRedirectURL
    )
    lazy var appRemote: SPTAppRemote = {
        print("2")
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    var playerViewController: ViewController {
        get {
            let navController = self.window?.rootViewController!.children[0] as! UIViewController
            return navController as! ViewController
        }
    }
    
    //MARK : Access session of spotify
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "https://testspotifysdk.herokuapp.com/api/token"),
            let tokenRefreshURL = URL(string: "https://testspotifysdk.herokuapp.com/api/refresh_token") {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""

        }
        //self.configuration.playURI = ""
        self.appRemote.playerAPI?.pause()
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    

    //MARK : request access to the required scope
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("3")
        // Override point for customization after application launch.
        
        /* scope note
         playlistReadPrivate    - Check if Users Follow a Playlist
                                - Get a List of Current User's Playlists
                                - Get a List of a User's Playlists
         userReadRecentlyPlayed - Get Current User's Recently Played Tracks
         userTopRead            - Get a User's Top Artists and Tracks
         
        */
        let requestedScopes: SPTScope = [.appRemoteControl, .playlistReadPrivate, .userReadRecentlyPlayed, .userTopRead]
        self.sessionManager.initiateSession(with: requestedScopes, options: .default)
        
        return true
    }
    
    //MARK : call this to redirect back to app
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("4")
        self.sessionManager.application(app, open: url, options: options)
        
        return true
    }
    
    //MARK : get access token
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("5")
        self.appRemote.connectionParameters.accessToken = session.accessToken
        Constants.sessionKey = session.accessToken
        self.appRemote.connect()
    }
    
    //MARK : Fail to get token
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("6")
        print(error)
    }
    
    //MARK: successfully renew token
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("7")
        print(session)
    }
    
    //MARK : init when app connect
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("connected")
        self.appRemote = appRemote
        playerViewController.appRemoteConnected()
        /*
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
        
        */
        self.appRemote.playerAPI?.pause()
        // Want to play a new track?
        // self.appRemote.playerAPI?.play("spotify:track:13WO20hoD72L0J13WTQWlT", callback: { (result, error) in
        //     if let error = error {
        //         print(error.localizedDescription)
        //     }
        // })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("8")
        print("disconnected")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("9")
        print("failed")
    }
    //MARK: access delegate
    class var sharedInstance: AppDelegate {
        get {
            return UIApplication.shared.delegate as! AppDelegate
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if self.appRemote.isConnected {
            //self.appRemote.disconnect()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
