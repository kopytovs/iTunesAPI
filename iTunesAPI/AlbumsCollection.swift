//
//  AlbumsCollection.swift
//  testItunesApi
//
//  Created by Sergey Kopytov on 22.02.2018.
//  Copyright © 2018 Sergey Kopytov. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import AZSearchView
import ViewAnimator
import TBEmptyDataSet

//class AlbumsCollection: UICollectionViewController, UICollectionViewDelegateFlowLayout, AZSearchViewDelegate, AZSearchViewDataSource, EmptyDataSetSource, EmptyDataSetDelegate{
class AlbumsCollection: UICollectionViewController, UICollectionViewDelegateFlowLayout, AZSearchViewDelegate, AZSearchViewDataSource, TBEmptyDataSetDelegate, TBEmptyDataSetDataSource{
    
    //reuse identifier for cell in collection view
    private let reuseIdentifier = "albumCell"
    
    //good sizes for flow layout
    private let cellWidth:CGFloat = 128
    private let cellHeight:CGFloat = 166
    private let spacing:CGFloat = 4
    
    //variable for follow all search actions
    private var searchActive = false
    
    //search controller
    private var search: AZSearchViewController!
    
    //array for autocomplete table
    var resultArray = [String]()
    
    //blank request
    private let request = "https://itunes.apple.com/search?"
    
    //big struct for saving many data about album (more of them for smth future features, not used now)
    struct Album {
        let artistID, collectionID: Int
        let artistName, collectionName, collectionCensoredName: String
        let collectionViewURL, artworkUrl100: String
        let collectionPrice: Double
        let collectionExplicitness: Bool
        let trackCount: Int
        
        init(artistID aID: Int, collectionID cID:Int, artistName arName: String, collectionName colName: String, collectionCensoredName colCensName: String, collectionViewURL colURL: String, artworkUrl100 artwork: String, collectionPrice price: Double, collectionExplictness explict: Bool, trackCount tracks: Int){
            
            artistID = aID
            collectionID = cID
            artistName = arName
            collectionName = colName
            collectionCensoredName = colCensName
            collectionViewURL = colURL
            artworkUrl100 = artwork
            collectionPrice = price
            collectionExplicitness = explict
            trackCount = tracks
        }
    }
    
    //array for collection view data source
    private var albums = [Album]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make some settings:
        
        //create search controller
        self.search = AZSearchViewController()
        self.search.delegate = self
        self.search.dataSource = self
        self.search.searchBarPlaceHolder = "Search albums"
        
        //set delegate and data source for empty data set
        collectionView?.emptyDataSetDataSource = self
        collectionView?.emptyDataSetDelegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //clear kingfisher cache
        ImageCache.default.clearMemoryCache()
    }
    
    //action for magnifier button
    @IBAction func searchButtonPressed(_ sender: Any) {
        self.search.show(in: self)
    }
    
    //action for unwind segue from album scene
    @IBAction func unwindSegueAlbums(segue: UIStoryboardSegue) {
        //there is nothing actions for unwind segue
        //if we want smth, we must write actions here
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "albumInfo"{
            let choosenAlbum = segue.destination as! AlbumViewController
            if let indexPaths = self.collectionView?.indexPathsForSelectedItems{
                let indexPath = indexPaths.first
                choosenAlbum.setAlbumID(ID: self.albums[(indexPath?.row)!].collectionID)
            }
        }
    }
    
    //make some animation
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let animation = AnimationType.from(direction: .bottom, offset: 40.0)
        cell.contentView.animate(animations: [animation])
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCell
        cell.nameLabel.text = albums[indexPath.row].collectionCensoredName
        cell.artworkImage.kf.indicatorType = .activity
        let url = URL(string: albums[indexPath.row].artworkUrl100)!
        let resource = ImageResource(downloadURL: url, cacheKey: albums[indexPath.row].artworkUrl100)
        cell.artworkImage.kf.setImage(with: resource, completionHandler: {
            (image, error, cacheType, imageUrl) in
            if image == nil{
                cell.artworkImage.image = #imageLiteral(resourceName: "empty-data")
            }
        })
        cell.artworkImage.layer.cornerRadius = cell.artworkImage.frame.width/32
        cell.artworkImage.clipsToBounds = true
        return cell
    }
    
    //Collection view flow layout delegate:
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns:CGFloat = ceil(collectionView.bounds.size.width / cellWidth)
        let size = (collectionView.bounds.size.width - ((columns-1)*spacing)) / columns
        return CGSize(width: size, height: size*1.3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }
    
    
    //AZSearch delegate and data source:
    
    //function for searching smth
    func searchView(_ searchView: AZSearchViewController, didSearchForText text: String) {
        self.loadData(for: text)
        self.searchActive = text.isEmpty ? false : true
        searchView.dismiss(animated: false, completion: nil)
    }
    
    //function for build autocomplete table
    func searchView(_ searchView: AZSearchViewController, didTextChangeTo text: String, textLength: Int)
    {
        if !text.isEmpty{
            let goodText = text.replacingOccurrences(of: " ", with: "+")
            let str = "\(self.request)country=ru&entity=album&term=\(goodText)&attribute=albumTerm&limit=10&media=music"
            let url = str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            self.buildAutocomplete(with: url!)
        } else {
            self.resultArray.removeAll()
            self.search.reloadData()
        }
    }
    
    //function for action when user selecting result
    func searchView(_ searchView: AZSearchViewController, didSelectResultAt index: Int, text: String) {
        self.searchActive = true
        searchView.dismiss(animated: true, completion: {
            self.loadData(for: self.resultArray[index])
        })
    }
    
    //function for actions after dismiss search
    func searchView(_ searchView: AZSearchViewController, didDismissWithText text: String) {
        if text.isEmpty{
            self.albums.removeAll()
            self.searchActive=false
            self.collectionView?.reloadData()
        }
    }
    
    //interface for results array
    func results() -> [String] {
        return self.resultArray
    }
    
    //empty data set data source:
    
    func imageForEmptyDataSet(in scrollView: UIScrollView) -> UIImage? {
        // return the image for EmptyDataSet
        if self.searchActive{
            return #imageLiteral(resourceName: "no-results")
        }else {
            return #imageLiteral(resourceName: "hello")
        }
    }
    
    //main title for data set
    func titleForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        // return the title for EmptyDataSet
        if self.searchActive{
            return NSAttributedString(string: "Sorry")
        }else {
            return NSAttributedString(string: "Hello!")
        }
    }
    //text for empty data set
    func descriptionForEmptyDataSet(in scrollView: UIScrollView) -> NSAttributedString? {
        // return the description for EmptyDataSet
        if self.searchActive{
            let attributedString = NSMutableAttributedString(string: "There is no albums by your search\n\nTry another search\n")
            let attributes0: [NSAttributedStringKey : Any] = [
                .font: UIFont(name: "HelveticaNeue", size: 18)!
            ]
            attributedString.addAttributes(attributes0, range: NSRange(location: 0, length: 33))
            let attributes2: [NSAttributedStringKey : Any] = [
                .foregroundColor: UIColor.orange,
                .font: UIFont(name: "HelveticaNeue", size: 22)!
            ]
            attributedString.addAttributes(attributes2, range: NSRange(location: 35, length: 18))
            return attributedString
        }else {
            let attributedString = NSMutableAttributedString(string: "Welcome to iTunes albums search. Let's start your music adventure!\n\nStart search\n")
            let attributes0: [NSAttributedStringKey : Any] = [
                .font: UIFont(name: "HelveticaNeue", size: 18)!
            ]
            attributedString.addAttributes(attributes0, range: NSRange(location: 0, length: 66))
            let attributes2: [NSAttributedStringKey : Any] = [
                .foregroundColor: UIColor.orange,
                .font: UIFont(name: "HelveticaNeue", size: 22)!
            ]
            attributedString.addAttributes(attributes2, range: NSRange(location: 68, length: 12))
            return attributedString
        }
    }
    
    //empty data set delegate:
    func emptyDataSetDidTapEmptyView(in scrollView: UIScrollView) {
        self.search.show(in: self)
    }
    
    //function for builing autocomplete table
    private func buildAutocomplete(with url: String){
        Alamofire.request(url).responseJSON(completionHandler: {response in
            switch response.result{
            case .success(let data):
                let myJson = JSON(data)
                if myJson["resultCount"].intValue>0{
                    self.resultArray.removeAll()
                    for index in 0...myJson["resultCount"].intValue-1{
                        self.resultArray.append(myJson["results"][index]["collectionName"].stringValue)
                    }
                    self.search.reloadData()
                }
                break
            case .failure(_):
                //error here means, that request for autocomplete tableview give back zero results
                //if this happened, application doing nothing,
                //then if user write smth bad, he will see only last positive requests
                break
            }
        })
    }
    
    //function for downloading albums by search bar text
    private func loadData(for search: String){
        self.albums.removeAll()
        let text = search.replacingOccurrences(of: " ", with: "+")
        let str = "\(self.request)country=ru&entity=album&term=\(text)&attribute=albumTerm&media=music"
        let url = str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        Alamofire.request(url!).responseJSON(completionHandler: {response in
            switch response.result{
            case .success(let data):
                let myJson = JSON(data)
                if myJson["resultCount"].intValue>0{
                    for index in 0...myJson["resultCount"].intValue-1{
                        let myAlbum = Album(artistID: myJson["results"][index]["artistId"].intValue, collectionID: myJson["results"][index]["collectionId"].intValue, artistName: myJson["results"][index]["artistName"].stringValue, collectionName: myJson["results"][index]["collectionName"].stringValue, collectionCensoredName: myJson["results"][index]["collectionCensoredName"].stringValue, collectionViewURL: myJson["results"][index]["collectionViewUrl"].stringValue, artworkUrl100: myJson["results"][index]["artworkUrl100"].stringValue, collectionPrice: myJson["results"][index]["collectionPrice"].doubleValue, collectionExplictness: (myJson["results"][index]["collectionExplicitness"].stringValue == "explict" ? true : false), trackCount: myJson["results"][index]["trackCount"].intValue)
                        self.albums.append(myAlbum)
                    }
                    self.albums = self.albums.sorted(by: {$0.collectionName<$1.collectionName})
                }
                self.collectionView?.reloadData()
                break
            case .failure(_):
                //here I can catch failure if needed
                //for example: if there is no results for user's search -
                //empty data set display this information
                self.searchActive = true
                break
            }
        })
    }

}
