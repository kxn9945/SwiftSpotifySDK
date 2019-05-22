//
//  ViewController.swift
//  Musinic
//
//  Created by Student on 4/15/19.
//  Copyright © 2019 Student. All rights reserved.
//

import UIKit
import StoreKit

let changeSongNotification = NSNotification.Name("changeSongNotification")

class ViewController: UIViewController, SPTAppRemotePlayerStateDelegate, SPTAppRemoteUserAPIDelegate, SKStoreProductViewControllerDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate {
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        playerState = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        playerState = nil
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        
    }
    
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: Constants.clientID, redirectURL: Constants.redirectURI)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating and App Remote can connect
        // otherwise another app switch will be required
        configuration.playURI = ""
        
        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "https://testspotifysdk.herokuapp.com/api/token")
        configuration.tokenRefreshURL = URL(string: "https://testspotifysdk.herokuapp.com/api/refresh_token")
        return configuration
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
        let scope: SPTScope = [.appRemoteControl, .playlistReadPrivate, .userReadRecentlyPlayed, .userTopRead]
        sessionManager.initiateSession(with: scope, options: .clientOnly)
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
    
    
    //MARK : Didn't use
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
        updateViewWithCapabilities(capabilities)
    }
    
    //MARK : Access playerstate
    var appRemote: SPTAppRemote {
        get {
            return AppDelegate.sharedInstance.appRemote
        }
    }
    
    private var playerState: SPTAppRemotePlayerState?
    private var subscribedToPlayerState: Bool = false
    
    //MARK: Get playerState
    private func getPlayerState() {
        appRemote.playerAPI?.getPlayerState { (result, error) -> Void in
            guard error == nil else { return }
            
            let playerState = result as! SPTAppRemotePlayerState
            print(playerState)
            self.updateViewWithPlayerState(playerState)
        }
    }

    
    @IBOutlet weak var ImageTrack: UIImageView!
    
    //MARK : IBACTION Play/Pause
    @IBAction func PlayBtn(_ sender: Any) {
        if !(appRemote.isConnected) {
            if (!appRemote.authorizeAndPlayURI("")) {
                // The Spotify app is not installed, present the user with an App Store page
                showAppStoreInstall()
            }
        } else if playerState == nil || playerState!.isPaused {
            
            startPlayback()
            
        } else {
            
            pausePlayback()
        }
 

        
    }
    //MARK : startTimer to update the sliderValue to match song duration
    func startTimer() throws {
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.SliderValueChange), userInfo: nil, repeats: true)
        
    }
    
    func showAlert() {
    }
    
    //MARK : Go back to Prev Song
    @IBAction func PrevBtn(_ sender: Any) {
        skipPrevious()
    }
    
    //MARK : Skip currentSong
    @IBAction func ForwardBtn(_ sender: Any) {
        skipNext()
    }
    
    //MARK : RepeatSong Toggle
    @IBAction func RepeatBtn(_ sender: Any) {
        toggleRepeatMode()
    }
    
    //MARK : enable/disable shuffle
    @IBAction func ShuffleBtn(_ sender: Any) {
        toggleShuffle()
    }
    
    //MARK : Access sliderValue and calculate the value to update slider
    @objc func SliderValueChange(){
        appRemote.playerAPI?.getPlayerState { (result, error) -> Void in
            guard error == nil else { return }
            
            let playerState = result as! SPTAppRemotePlayerState
            
            let someIntToUInt: Float = Float(playerState.playbackPosition )
            let other: Float = Float(playerState.track.duration )
            
            
            self.Slider.value = someIntToUInt / other * 100
            
        }
        

 
    }
    
    //MARK : Update time remaining for song with slider value
    @IBAction func ValueChange(_ sender: Any) {
        guard let playerState = playerState else { return }
        let other: Int = Int(Float(playerState.track.duration ) * Float(self.Slider.value)/100)
            
            
            
        appRemote.playerAPI?.seek(toPosition: other, callback: { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
            
 
    }
    
    
    @IBOutlet weak var Slider: UISlider!

    //MARK : -FUNCTION-
    //UPDATE Image
    private func updatePlayPauseButtonState(_ paused: Bool) {
        let playPauseButtonImage = paused ? UIImage(named: "play.png") : UIImage(named: "pause.png")
        PlayBtn.setImage(playPauseButtonImage, for: UIControl.State())
        PlayBtn.setImage(playPauseButtonImage, for: .highlighted)
    }
    
    private func updateRepeatModeLabel(_ repeatMode: SPTAppRemotePlaybackOptionsRepeatMode) {
            switch repeatMode {
            case .off:
                repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.normal)
                repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.highlighted)
                return
            case .track:
                repeatBtn.setImage(UIImage(named: "repeat-two.png"), for: UIControl.State.normal)
                repeatBtn.setImage(UIImage(named: "repeat-two.png"), for: UIControl.State.highlighted)
                return
            case .context:
                repeatBtn.setImage(UIImage(named: "repeat-one.png"), for: UIControl.State.normal)
                repeatBtn.setImage(UIImage(named: "repeat-one.png"), for: UIControl.State.highlighted)

                return
            default:
                repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.normal)
                repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.highlighted)
                return
            }
    }
    
    private func updateShuffleLabel(_ isShuffling: Bool) {
        let playPauseButtonImage = isShuffling ? UIImage(named: "shuffle.png") : UIImage(named: "shuffle-on.png")
        shuffleBtn.setImage(playPauseButtonImage, for: UIControl.State())
        shuffleBtn.setImage(playPauseButtonImage, for: .highlighted)
    }
    
    //MARK : update playerStatus when getPlayerState is called
    private func updateViewWithPlayerState(_ playerState: SPTAppRemotePlayerState) {
        //print(playerState)
        updatePlayPauseButtonState(playerState.isPaused)
        updateRepeatModeLabel(playerState.playbackOptions.repeatMode)
        updateShuffleLabel(playerState.playbackOptions.isShuffling)
        currentSong.text = playerState.track.name + " - " + playerState.track.artist.name
        fetchAlbumArtForTrack(playerState.track) { (image) -> Void in
            self.updateAlbumArtWithImage(image)
        }
    }
    
    
    
    @IBOutlet weak var PlayBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var forwardBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    
    @IBOutlet weak var currentSong: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        currentSong.text = "None"

        PlayBtn.setImage(UIImage(named: "play.png"), for: UIControl.State.normal)
        PlayBtn.setImage(UIImage(named: "play.png"), for: UIControl.State.highlighted)
        
        shuffleBtn.setImage(UIImage(named: "shuffle.png"), for: UIControl.State.normal)
        shuffleBtn.setImage(UIImage(named: "shuffle.png"), for: UIControl.State.highlighted)
        
        prevBtn.setImage(UIImage(named: "rewind.png"), for: UIControl.State.normal)
        prevBtn.setImage(UIImage(named: "rewind.png"), for: UIControl.State.highlighted)
        
        forwardBtn.setImage(UIImage(named: "fast-forward.png"), for: UIControl.State.normal)
        forwardBtn.setImage(UIImage(named: "fast-forward.png"), for: UIControl.State.highlighted)
        
        repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.normal)
        repeatBtn.setImage(UIImage(named: "repeat.png"), for: UIControl.State.highlighted)


        do {
            try startTimer()
        }
        catch{
            self.showAlert()
        }
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(changeSong), name: changeSongNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //storeKit
    private func showAppStoreInstall() {
        if TARGET_OS_SIMULATOR != 0 {
        } else {
            let loadingView = UIActivityIndicatorView(frame: view.bounds)
            view.addSubview(loadingView)
            loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            let storeProductViewController = SKStoreProductViewController()
            storeProductViewController.delegate = self
            storeProductViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: SPTAppRemote.spotifyItunesItemIdentifier()], completionBlock: { (success, error) in
                loadingView.removeFromSuperview()
                if let error = error {
                    self.presentAlert(
                        title: "Error accessing App Store",
                        message: error.localizedDescription)
                } else {
                    self.present(storeProductViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    private func displayError(_ error: NSError?) {
        if let error = error {
            presentAlert(title: "Error", message: error.description)
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK : Set default callback for appremote function
    var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[weak self] _, error in
                if let error = error {
                    self?.displayError(error as NSError)
                }
            }
        }
    }
    
    //MARK : skip song
    private func skipNext() {
        appRemote.playerAPI?.skip(toNext: defaultCallback)
    }
    //MARK : access previous song
    private func skipPrevious() {
        appRemote.playerAPI?.skip(toPrevious: defaultCallback)
    }
    
    //MARK : set playState to play
    private func startPlayback() {
        appRemote.playerAPI?.resume(defaultCallback)
    }
    //MARK : set playState to pause
    private func pausePlayback() {
        appRemote.playerAPI?.pause(defaultCallback)
    }
    //MARK toggle shuffle state
    private func toggleShuffle() {
        guard let playerState = playerState else { return }
        appRemote.playerAPI?.setShuffle(!playerState.playbackOptions.isShuffling, callback: defaultCallback)
    }
    //MARK : Play song given that you have URI
    private func playTrackWithIdentifier(_ identifier: String) {
        appRemote.playerAPI?.play(identifier, callback: defaultCallback)
    }
    //MARK : Toggle repeat to off -> repeat playlist -> repeat song
    private func toggleRepeatMode() {
        guard let playerState = playerState else { return }
        let repeatMode: SPTAppRemotePlaybackOptionsRepeatMode = {
            switch playerState.playbackOptions.repeatMode {
            case .off: return .context
            case .context: return .track
            case .track: return .off
                
            default: return .off
            }
        }()
        
        appRemote.playerAPI?.setRepeatMode(repeatMode, callback: defaultCallback)
    }
    
    //MARK : Get Album Image from track infomation
    private func fetchAlbumArtForTrack(_ track: SPTAppRemoteTrack, callback: @escaping (UIImage) -> Void ) {
        appRemote.imageAPI?.fetchImage(forItem: track, with:CGSize(width: 1000, height: 1000), callback: { (image, error) -> Void in
            guard error == nil else { return }
            
            let image = image as! UIImage
            callback(image)
        })
    }
    // When playerState change this get call
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        self.playerState = playerState
        updateViewWithPlayerState(playerState)
    }
    
    // MARK : UPDATE IMG
    private func updateAlbumArtWithImage(_ image: UIImage) {
        self.ImageTrack.image = image
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.fade
        self.ImageTrack.layer.add(transition, forKey: "transition")
    }
    
    //MARK : Didn't use
    private func updateViewWithCapabilities(_ capabilities: SPTAppRemoteUserCapabilities) {
    }
    
    func showError(_ errorDescription: String) {
        let alert = UIAlertController(title: "Error!", message: errorDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK : Subscribe to playerState so user get update on playerState
    private func subscribeToPlayerState() {
        guard (!subscribedToPlayerState) else { return }
        appRemote.playerAPI!.delegate = self
        appRemote.playerAPI?.subscribe { (_, error) -> Void in
            guard error == nil else { return }
            self.subscribedToPlayerState = true
        }
    }
    
    func appRemoteConnecting() {
    }
    
    //MARK : When connected
    func appRemoteConnected() {
        getPlayerState()
        subscribeToPlayerState()
        
    }
    
    func appRemoteDisconnect() {
        self.subscribedToPlayerState = false
    }
    
    //MARK : Noti from DataViewController
    @objc func changeSong(notification:Notification){
        if (notification.userInfo?["data"] as? String) != nil{
            let song = notification.userInfo?["data"] as! String
            self.appRemote.playerAPI?.play(song, callback: { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
             })
        }
    }


}

