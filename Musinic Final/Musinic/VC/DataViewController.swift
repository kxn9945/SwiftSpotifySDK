//
//  DataViewController.swift
//  Musinic
//
//  Created by Student on 5/1/19.
//  Copyright © 2019 Student. All rights reserved.

//https://spotify.github.io/ios-sdk/html/
//https://developer.spotify.com/documentation/general/guides/scopes/#playlist-read-private

import UIKit

private let reuseIdentifier = "Cell"

let renewSearchNotification = NSNotification.Name("renewSearchNotification")

class DataViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    let defaults = UserDefaults.standard
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return objectResponse2?.tracks?.count ?? 0
    }
    
    
    // Set Img and song name to the cell of collectionview that is attach to this view controller
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DisplayCell", for: indexPath) as! DisplayArtistViewCell
        
        
        let url = URL(string: objectResponse2?.tracks?[indexPath.row].album?.images?[0].url ?? "https://www.triad-av.com/liveProductions/img/Flag_of_None.svg.png")
        
        
        cell.ArtistLabel.text = objectResponse2?.tracks?[indexPath.row].name
        cell.ImgView.load(url: url!)
        return cell
    }
    
    // NOti to ViewController to change song
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let nc = NotificationCenter.default
        let data = ["data": objectResponse2?.tracks?[indexPath.row].uri]
        nc.post(name: changeSongNotification, object: self, userInfo:data as [AnyHashable : Any])
    }
    
    
    
    var objectResponse:Response?
    
    var objectResponse2:Response2?
    
    @objc func renewSearch(notification:Notification){
        loadData()
        titleLabel.text = DataInfo.shared.songName
    }
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var currentSongInfo: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataInfo.shared.songID = defaults.object(forKey:"id") as! String
        DataInfo.shared.songName = defaults.object(forKey:"songName") as! String
        objectResponse?.artists?[0].id = defaults.object(forKey:"artistID") as? String
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        titleLabel.text = DataInfo.shared.songName
        loadData()
        
        // Register cell classes


        // Do any additional setup after loading the view.
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(renewSearch), name: renewSearchNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK : -Load data from spotify-
    func loadData(){
        let scriptUrl = "https://api.spotify.com/v1/tracks"
        // Add one parameter
        let urlWithParams = scriptUrl + "/\(DataInfo.shared.songID)?market=ES"
        
        // Create NSURL Ibject
        let myUrl = NSURL(string: urlWithParams);
        
        // Creaste URL Request
        let request = NSMutableURLRequest(url:myUrl! as URL);
        
        // Set request HTTP method to GET. It could be POST as well
        request.httpMethod = "GET"
        
        request.addValue("Bearer " + Constants.sessionKey , forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // Check for error
            if error != nil
            {
                print("error=\(String(describing: error))")
                return
            }
            
            guard let data = data else{
                print("No data!")
                return
            }

            do{
                self.objectResponse = try JSONDecoder().decode(Response.self, from: data)
            }catch{
                print(error)
            }
            


            DispatchQueue.main.async { [weak self] in
                //self?.collectionView.reloadData()
                self?.defaults.set(DataInfo.shared.songName, forKey: "songName")
                self?.defaults.set(DataInfo.shared.songID, forKey: "id")
                self?.defaults.set(self?.objectResponse?.artists?[0].id, forKey: "artistID")
                
                self?.loadArtistData()
                self?.currentSongInfo.text = "Written by: \(self?.objectResponse?.artists?[0].name ?? "") \n Album Type: \(self?.objectResponse?.album?.album_type ?? "") \n Released in: \(self?.objectResponse?.album?.release_date ?? "") \n Song Time: \((self?.objectResponse?.duration_ms ?? 0).msToSeconds.minuteSecondMS) \n Popularity Score: \(self?.objectResponse?.popularity ?? 0)"
            }
        }
        
        task.resume()
        
    }
    
    //MARK : -Load Artist data from spotify-
    //Should be able to collapse this into 1 function
    func loadArtistData(){
        let scriptUrl = "https://api.spotify.com/v1/artists"
        // Add one parameter
        
        let urlWithParams = scriptUrl + "/\(objectResponse?.artists?[0].id ?? "")/top-tracks?country=ES"
        // Create NSURL Ibject
        let myUrl = NSURL(string: urlWithParams);
        
        // Creaste URL Request
        let request = NSMutableURLRequest(url:myUrl! as URL);
        
        // Set request HTTP method to GET. It could be POST as well
        request.httpMethod = "GET"
        
        request.addValue("Bearer " + Constants.sessionKey , forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // Check for error
            if error != nil
            {
                print("error=\(String(describing: error))")
                return
            }
            
            guard let data = data else{
                print("No data!")
                return
            }
            
            // Print out response string
            //let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            //print("responseString = \(responseString)")
            
            do{
                self.objectResponse2 = try JSONDecoder().decode(Response2.self, from: data)
            }catch{
                print(error)
            }
            /*
             do{
             self.objectWrap = try JSONDecoder().decode(ObjectWrapper.self, from: data)
             }catch{
             print(error)
             }
             */
            
            
            
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
                
            }
        }
        
        task.resume()
        
    }
        
    


}
//Convert Time
extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%d:%02d.%03d", minute, second, millisecond)
    }
    var minute: Int {
        return Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        return Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
