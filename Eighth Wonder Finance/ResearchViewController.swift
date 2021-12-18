//
//  ResearchViewController.swift
//  Eighth Wonder Finance
//
//  Created by James Lipe on 10/27/21.
//

import UIKit
import AlamofireImage

class ResearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct StockInfo : Codable {
        var symbol: String
        var companyName: String
        var latestPrice: Float
        var marketCap: Int
        var changePercent: Float
        
        enum CodingKeys: String, CodingKey {
            case symbol
            case companyName
            case latestPrice
            case marketCap
            case changePercent
        }
    }
    
    struct Logo : Codable {
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
    }
    
    var stockResearchType = "watchlist"
    
    @IBAction func onSelectStockListButton(_ sender: Any) {
        let ac = UIAlertController(title: "Stock List", message: "select stocks to research", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Gainers", style: .default, handler: { (_) in
            if self.stockResearchType == "gainers" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("Gainers", for: .normal)
                self.stockResearchType = "gainers"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "Losers", style: .default, handler: { (_) in
            if self.stockResearchType == "losers" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("Losers", for: .normal)
                self.stockResearchType = "losers"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "Most Active", style: .default, handler: { (_) in
            if self.stockResearchType == "mostactive" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("Most Active", for: .normal)
                self.stockResearchType = "mostactive"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "IEX Volume", style: .default, handler: { (_) in
            if self.stockResearchType == "iexvolume" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("IEX Volume", for: .normal)
                self.stockResearchType = "iexvolume"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "IEX Percent", style: .default, handler: { (_) in
            if self.stockResearchType == "iexpercent" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("IEX Percent", for: .normal)
                self.stockResearchType = "iexpercent"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "Watch List", style: .default, handler: { (_) in
            if self.stockResearchType == "watchlist" {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.stockListButton.setTitle("Watch List", for: .normal)
                self.stockResearchType = "watchlist"
                self.getStockInfo(successCallback: self.handleStockInfo)
            }
        }))
        ac.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        present(ac, animated: true)
    }
    
    @IBOutlet weak var stockListButton: UIButton!
    
    var stocks: [StockInfo] = []
    var logos: [String:Logo] = [:]
    
    @IBOutlet weak var tableView: UITableView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stock = stocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResearchStockCell") as! ResearchStockCell
        cell.stockName.text = stock.companyName
        cell.currentPrice.text = "Current Price: $\(stock.latestPrice)"
        let percentChange = abs(Float(stock.changePercent) * 100)
        let roundedChange = round(percentChange * 100) / 100.0
        cell.percentChange.text = "\(roundedChange)%"
        if Float(stock.changePercent) < 0 {
            cell.percentChange.textColor = UIColor.systemRed
        } else {
            cell.percentChange.textColor = UIColor.systemGreen
        }
        
        // "https://storage.googleapis.com/iexcloud-hl37opg/api/logos/PETZ.png" //this is default logo
        let logo = logos[stock.symbol]
        var logoURLString = logo?.url ?? "https://media.baamboozle.com/uploads/images/407556/1624173273_168575_gif-url.gif"
        let logoURL = URL(string: logoURLString)!
        
        cell.stockLogo.af.setImage(withURL: logoURL)
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "researchDetailSegue" {
            let destination = segue.destination as! ResearchDetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedStock = stocks[indexPath.row] as StockInfo
            destination.companyNameToDisplay = selectedStock.companyName
            destination.companySymbol = selectedStock.symbol
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getLogos() {
        // https://stackoverflow.com/questions/35906568/wait-until-swift-for-loop-with-asynchronous-network-requests-finishes-executing
        let myGroup = DispatchGroup()
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        for stock in self.stocks {
            myGroup.enter()
            let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(stock.symbol)/logo?token=pk_246252e7872a41e4bb86d8c546d5e510")!
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let task = session.dataTask(with: request) { (data, response, error) in
                // This runs when network request returns
                if let error = error {
                    print(error.localizedDescription)
                } else if let data = data {
                    let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    
                    let urlPath = dataDictionary["url"] as? String
            
                    if (urlPath != nil) && (urlPath != "") {
                        let logo = Logo(url: urlPath!)
                        self.logos[stock.symbol] = logo
                    } else {
                        let logo = Logo(url: "https://media.baamboozle.com/uploads/images/407556/1624173273_168575_gif-url.gif")

                        self.logos[stock.symbol] = logo
                    }
                    myGroup.leave()
                }
            }
            task.resume()
        }
        myGroup.notify(queue: .main) {
            print("finished all requests")
            self.tableView.reloadData()
        }
    }
    
    
    func getStockInfo(successCallback: @escaping ([StockInfo]) -> ()) {
        // https://learnappmaking.com/urlsession-swift-networking-how-to/
        if stockResearchType == "watchlist" {
            let defaults = UserDefaults.standard
            var watchList = [String]()
            if defaults.array(forKey: "defaultWatchList") as? [String] == nil {
                WatchList()
                watchList = defaults.array(forKey: "defaultWatchList") as! [String]
            } else {
                watchList = defaults.array(forKey: "defaultWatchList") as! [String]
            }
        
            var stockResponseArray: [StockInfo] = []
            
            for watchStock in watchList {
                let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(watchStock)/quote?token=pk_246252e7872a41e4bb86d8c546d5e510")!
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
                        let stockResponse = try JSONDecoder().decode(StockInfo.self, from: data!) as StockInfo
                        stockResponseArray.append(stockResponse)
                        if watchList.count == stockResponseArray.count {
                            successCallback(stockResponseArray)
                        }
                
                    } catch {
                        print("JSON error: \(error.localizedDescription)")
                    }
                }
                task.resume()
            }

        } else {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/\(stockResearchType)?token=pk_246252e7872a41e4bb86d8c546d5e510")!
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
                let stockResponse = try JSONDecoder().decode([StockInfo].self, from: data!) as [StockInfo]
                successCallback(stockResponse)
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        }
        task.resume()
        }
    }
    
    func handleStockInfo(stockArray: [StockInfo]) -> Void {
        stocks = stockArray
        getLogos()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        //tableView.delegate = self
        //tableView.dataSource = self
        //getStockInfo(successCallback: handleStockInfo)
        //self.title = "Explore"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        getStockInfo(successCallback: handleStockInfo)
        self.title = "Explore"
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
