//
//  SearchViewController.swift
//  Musinic
//
//  Created by Student on 4/23/19.
//  Copyright © 2019 Student. All rights reserved.
//

import UIKit



class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate{
    
    
    var objectResponse:searchViewResponse?
    
    

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return objectResponse?.tracks?.items?.count ?? 0
    }
    

    //Display img and song name in collectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! displayCollectionViewCell
        

        let url = URL(string: objectResponse?.tracks?.items?[indexPath.row].album?.images?[0].url ?? "https://www.triad-av.com/liveProductions/img/Flag_of_None.svg.png")
        let data = try? Data(contentsOf: url!)
        
        cell.myLabel.text = objectResponse?.tracks?.items?[indexPath.row].name
        cell.imgView.image = UIImage(data: data!)
        return cell
    }
    
    //Sent data to DataFlipPage when click at any item in the cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DataInfo.shared.songID = objectResponse?.tracks?.items?[indexPath.row].id ?? ""
        let nc = NotificationCenter.default
        let data = ["data": objectResponse?.tracks?.items?[indexPath.row].name]
        nc.post(name: changeViewNotification, object: self, userInfo:data as [AnyHashable : Any])
    }
    

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    var tableData = [String]()
    var itunesResults:ITunesResults?


    //Normal search bar with loadData attach
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchText \(searchText)")
        let xString = searchText.replacingOccurrences(of: " ", with: "%20")
        loadData(text: xString)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchText \(String(describing: searchBar.text))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    //Load data from spotify
    func loadData(text: String){
        let scriptUrl = "https://api.spotify.com/v1/search"
        // Add one parameter
        let urlWithParams = scriptUrl + "?q=\(text)&type=track&market=US&limit=24"
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
                print("error=\(error as Optional)")
                return
            }
            
            guard let data = data else{
                print("No data!")
                return
            }
            
            // Print out response string
            let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString as Optional)")
            do{
                self.objectResponse = try JSONDecoder().decode(searchViewResponse.self, from: data)
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
                //self?.collectionView.reloadData()
                self?.collectionView.reloadData()
            }
        }
        
        task.resume()
        
    }
    
    

}
