//
//  ResearchDetailViewController.swift
//  Eighth Wonder Finance
//
//  Created by James Lipe on 10/29/21.
//

import UIKit
import AlamofireImage

class ResearchDetailViewController: UIViewController {
    
    struct Logo : Codable {
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
    }
    
    struct CompanyInfo : Codable {
        var description: String
        var website: String
        
        enum CodingKeys: String, CodingKey {
            case description
            case website
        }
    }

    var companyNameToDisplay = ""
    var companySymbol = ""
    var companyLogoURL = ""
    
    
    @IBOutlet weak var websiteLink: UITextView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyLogoImage: UIImageView!
    @IBOutlet weak var companyDescriptionView: UITextView!
    @IBOutlet weak var watchlistButtonOutlet: UIButton!
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "researchToBuySegue" {
            let destination = segue.destination as! TradeViewViewController
            destination.symbol = companySymbol
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        websiteLink.isEditable = false
        websiteLink.dataDetectorTypes = UIDataDetectorTypes.all
        companyNameLabel.text = companyNameToDisplay
        getLogoUrl(symbol: companySymbol)
        getCompanyInfo(symbol: companySymbol)
        if checkWatchList() {
            //watchlistButtonOutlet.setTitle("Remove from Watchlist", for: .normal)
            formatRemoveWatchlistButton()
        } else {
            //watchlistButtonOutlet.setTitle("Add to Watchlist", for: .normal)
            formatAddWatchlistButton()
        }
            
        
    }
    
    func getCompanyInfo(symbol: String) {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/company?token=pk_246252e7872a41e4bb86d8c546d5e510")!
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: url) { data, response, error in
            if error != nil {
                print("Error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Bad http response code")
                return
            }
            guard let mime = response?.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            do {
                let infoResponse = try JSONDecoder().decode(CompanyInfo.self, from: data!) as CompanyInfo
                self.companyDescriptionView.text = infoResponse.description
                self.websiteLink.text = infoResponse.website
//                self.companyLogoURL = infoResponse.url
//                let url = URL(string: self.companyLogoURL)
//                if url == nil {
//                    return
//                } else {
//                    self.companyLogoImage.af.setImage(withURL: url!)
//                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }

        }
        task.resume()
    }
    
    func getLogoUrl(symbol: String) {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=pk_246252e7872a41e4bb86d8c546d5e510")!
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: url) { data, response, error in
            if error != nil {
                print("Error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Bad http response code")
                return
            }
            guard let mime = response?.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            do {
                let stockResponse = try JSONDecoder().decode(Logo.self, from: data!) as Logo
                self.companyLogoURL = stockResponse.url
                let url = URL(string: self.companyLogoURL)
                if url == nil {
                    return
                } else {
                    self.companyLogoImage.af.setImage(withURL: url!)
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }

        }
        task.resume()
    }
    
    
    @IBAction func watchlistButton(_ sender: Any) {
        let defaults = UserDefaults.standard
        var watchList = [String]()
        watchList = defaults.array(forKey: "defaultWatchList") as! [String]
        
        if checkWatchList() {
            // Remove stock from watch list and update user defaults
            let modifiedWatchList = watchList.filter{$0 != companySymbol}
            defaults.set(modifiedWatchList, forKey: "defaultWatchList")
            
            // Set button text to Add
           // watchlistButtonOutlet.setTitle("Add to Watchlist", for: .normal)
            formatAddWatchlistButton()
        } else {
            // Add stock to watch list and update user defaults
            var modifiedWatchList = watchList
            modifiedWatchList.append(companySymbol)
            defaults.set(modifiedWatchList, forKey: "defaultWatchList")
            
            // Set button test to remove
            //watchlistButtonOutlet.setTitle("Remove from Watchlist", for: .normal)
            formatRemoveWatchlistButton()
            
        }
    }
    
    func checkWatchList() -> Bool {
        let defaults = UserDefaults.standard
        var watchList = [String]()
        if defaults.array(forKey: "defaultWatchList") as? [String] == nil {
            WatchList()
            watchList = defaults.array(forKey: "defaultWatchList") as! [String]
        } else {
            watchList = defaults.array(forKey: "defaultWatchList") as! [String]
        }
        for symbol in watchList {
            if companySymbol == symbol {
                return true
            }
        }
        return false
    }
    
    func formatAddWatchlistButton() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]

        let addWatchlistAttributedString = NSAttributedString(string: "Add to Watchlist", attributes: attributes)
       
        watchlistButtonOutlet.setAttributedTitle(addWatchlistAttributedString, for: .normal)
    }
    
    func formatRemoveWatchlistButton() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        let removeWatchlistAttributedString = NSAttributedString(string: "Remove from Watchlist", attributes: attributes)
        watchlistButtonOutlet.setAttributedTitle(removeWatchlistAttributedString, for: .normal)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
