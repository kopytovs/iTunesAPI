//
//  AlbumViewController.swift
//  testItunesApi
//
//  Created by Sergey Kopytov on 25.02.2018.
//  Copyright © 2018 Sergey Kopytov. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import CDAlertView
import AVFoundation
import ESTMusicIndicator

class AlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //identifier of cell
    private let reuseIdentifier = "songCell"
    
    //array for table view data source
    private var names = [Song]()
    
    //point of entry to this controller, all information is downloaded by Lookup API with this ID
    private var albumID:Int?
    
    //url of displaying all information about album in iTunes
    private var albumUrl: String?
    
    //player for sample sound of songs
    private var player = AVPlayer()
    
    //variable for music indicator manipulation
    //(first data shows what row user tap, second shows playing music in this row or not)
    private var currentCellOptions = [-1, false] as [Any]
    
    //struct for incapsuation all data of song
    struct Song{
        let trackName: String
        let trackTime: String
        let trackViewUrl: String
        let trackPreviewUrl: String
        let trackID: Int
        let collectionID: Int
        let artistID: Int
        
        init(trackName name: String, trackTime time: String, trackViewUrl url: String, trackPreviewUrl prev: String, trackID tID: Int, collectionID cID: Int, artistID aID: Int){
            trackName = name
            trackTime = time
            trackViewUrl = url
            trackPreviewUrl = prev
            trackID = tID
            collectionID = cID
            artistID = aID
        }
        
    }
    
    //all outlets of views in this scene
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var countTrackLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set tableView delegate and data source
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //hide all views until data is downloaded
        self.hideAll(really: true)
        
        //make some addons to "buy" button
        buyButton.layer.borderWidth = 1.0
        buyButton.layer.borderColor = UIColor.orange.cgColor
        
        //make album atwork more pleasant
        artworkView.layer.cornerRadius = artworkView.frame.width/24
        artworkView.clipsToBounds = true
        
        //load all data of album from iTunes lookup api
        self.loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //clear kingfisher cache
        ImageCache.default.clearMemoryCache()
    }
    
    //tableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int{
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MusicCell
        cell.indicator.state = (indexPath.row == self.currentCellOptions[0] as! Int) ? .playing : .stopped
        cell.timeLabel.isHidden = (cell.indicator.state == .playing) ? true : false
        cell.numberLabel.text = "\(indexPath.row+1)"
        cell.nameLabel.text = self.names[indexPath.row].trackName
        cell.timeLabel.text = self.names[indexPath.row].trackTime
        
        return cell
    }
    
    //tableView delegate:
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = URL(string: self.names[indexPath.row].trackPreviewUrl)
        let selected = (self.currentCellOptions[1] as! Bool && indexPath.row == self.currentCellOptions[0] as! Int) ? true : false
        //if this is the second tap = app must stop music, else - play
        if selected{
            player.pause()
            self.currentCellOptions[1] = false
            self.currentCellOptions[0] = -1
        } else {
            let playerItem = AVPlayerItem(url: url!)
            player = AVPlayer(playerItem: playerItem)
            player.rate = 1.0
            player.play()
            self.currentCellOptions[1] = true
        }
        self.updateIndicators(indexPath: indexPath, selected: !selected)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //method for viewing album in iTunes
    @IBAction func buyAlbum(_ sender: Any) {
        let url = URL(string: self.albumUrl!)
        UIApplication.shared.open(url!)
    }
    
    //function for downloading all data from server
    private func loadData(){
        let url = "https://itunes.apple.com/lookup?id=\(albumID ?? 0)&entity=song&country=ru"
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.view.addSubview(activityIndicator)
        activityIndicator.frame = self.view.bounds
        activityIndicator.startAnimating()
        Alamofire.request(url).responseJSON(completionHandler: { response in
            switch response.result{
            case .success(let data):
                let myJson = JSON(data)
                if myJson["resultCount"].intValue > 0{
                    for index in 1...myJson["resultCount"].intValue-1{
                        let mySong = Song(trackName: myJson["results"][index]["trackName"].stringValue, trackTime: self.timeDuration(mills: myJson["results"][index]["trackTimeMillis"].intValue), trackViewUrl: myJson["results"][index]["trackViewUrl"].stringValue, trackPreviewUrl: myJson["results"][index]["previewUrl"].stringValue, trackID: myJson["results"][index]["trackId"].intValue, collectionID: myJson["results"][index]["collectionId"].intValue, artistID: myJson["results"][index]["artistId"].intValue)
                        self.names.append(mySong)
                        }
                    self.tableView.reloadData()
                    self.albumUrl = myJson["results"][0]["collectionViewUrl"].stringValue
                    self.countTrackLabel.text = "Tracks: " + myJson["results"][0]["trackCount"].stringValue
                    self.copyrightLabel.text = myJson["results"][0]["copyright"].stringValue
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    let convertedDate = formatter.date(from: myJson["results"][0]["releaseDate"].stringValue)
                    formatter.dateFormat = "dd MMMM yyyy"
                    formatter.timeZone = TimeZone.current
                    formatter.locale = Locale.current
                    let time = formatter.string(from: convertedDate!)
                    self.dateLabel.text = time
                    let price: String = self.makePrice(for: myJson["results"][0]["collectionPrice"].stringValue, currency: myJson["results"][0]["currency"].stringValue)
                    self.buyButton.setTitle(price, for: [])
                    let url = URL(string: myJson["results"][0]["artworkUrl100"].stringValue)!
                    let resource = ImageResource(downloadURL: url, cacheKey: myJson["results"][0]["artworkUrl100"].stringValue)
                    self.artworkView.kf.setImage(with: resource, completionHandler: {
                        (image, error, cacheType, imageUrl) in
                        //if album doesn't have any image - show templeate "empty" image
                        if image == nil{
                            self.artworkView.image = #imageLiteral(resourceName: "empty-data")
                        }
                        })
                    self.albumLabel.text = myJson["results"][0]["collectionCensoredName"].stringValue
                    self.artistLabel.text = myJson["results"][0]["artistName"].stringValue
                    activityIndicator.removeFromSuperview()
                    self.hideAll(really: false)
                } else {
                    //shows, if smth happened with json data or with iTunes, because this
                    //error only shows, when response is .success but doesn't have any data
                    self.showTrouble(error: "Something goes wrong")
                }
                break
            case .failure(let error):
                //if smth goes wrong - alert notification show it to user and give two options:
                //repeat request or return to all albums collection
                activityIndicator.removeFromSuperview()
                self.showTrouble(error: error.localizedDescription)
                break
            }
        })
    }
    
    //interface for setting album ID to download all data
    public func setAlbumID(ID: Int){
        self.albumID = ID
    }
    
    //function for converting currency, it can be bigger
    private func makePrice(for price: String, currency value: String) -> String{
        switch value{
        case "USD":
            return "$\(price)"
        case "EUR":
            return "€\(price)"
        case "GBP":
            return "£\(price)"
        case "RUB":
            return "\(price)₽"
        default:
            return "\(price)"
        }
    }
    
    //small function for MM:ss time of track by mills
    private func timeDuration(mills mil: Int) -> String{
        let sec = mil/1000
        let minutes = sec/60
        let seconds = sec - minutes*60
        let result = "\(minutes):\(seconds>10 ? "\(seconds)" : "0\(seconds)")"
        return result
    }
    
    //function for display error message
    private func showTrouble(error msg: String){
        //make and display CD Alert View
        let alert = CDAlertView(title: "Error", message: msg, type: .error)
        let doneAction = CDAlertViewAction(title: "Repeat", handler: {action in
            self.loadData()
        })
        alert.add(action: doneAction)
        let nevermindAction = CDAlertViewAction(title: "Break", handler: {action in
            self.performSegue(withIdentifier: "unwindSegue", sender: self)
        })
        alert.add(action: nevermindAction)
        alert.show()
    }
    
    //function for manipilating with music indicators :)
    private func updateIndicators(indexPath: IndexPath, selected: Bool){
        
        //set all indicators to .off
        for cell in tableView.visibleCells as! [MusicCell]{
            cell.timeLabel.isHidden = false
            cell.indicator.state = .stopped
        }
        
        //set choosen indicator to .on (selected parameter means, that this is the first tap
        //because second tap means .stop)
        if selected{
            let playCell = tableView.cellForRow(at: indexPath) as! MusicCell
            playCell.indicator.state = .playing
            self.currentCellOptions[0] = indexPath.row
            playCell.timeLabel.isHidden = true
        }
    }
    
    //function for hide/unhide all UIViews (without content view and indicators, of course)
    private func hideAll(really: Bool){
        tableView.isHidden = really
        artworkView.isHidden = really
        albumLabel.isHidden = really
        artistLabel.isHidden = really
        countTrackLabel.isHidden = really
        buyButton.isHidden = really
        copyrightLabel.isHidden = really
        dateLabel.isHidden = really
    }
}
