//
//  HomeViewController.swift
//  Eighth Wonder Finance
//
//  Created by Joshua Harris on 10/24/21.
//

import UIKit
import Parse
import AlamofireImage

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
    
    struct OwnedStockInfo : Codable {
        var symbol: String
        var cost: Float
        var quantity: Int
        
        enum CodingKeys: String, CodingKey {
            case symbol
            case cost
            case quantity
        }
    }
    
    struct Logo : Codable {
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
    }
    
    
    
    @IBOutlet weak var tableView: UITableView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var sharecurrentvalue = 0.0 as Float
        var sharepreviousvalue = 0.0 as Float
        var sharechange = 0.0 as Float
        var ownedshares = 0
        let stock = stocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PortfolioStockCell") as! PortfolioStockCell
        cell.stockName.text = stock.companyName
        for ownedStocks in self.ownedStockArray{
            if stock.symbol == ownedStocks.symbol{
                sharecurrentvalue += stock.latestPrice * Float(ownedStocks.quantity)
                sharepreviousvalue = ownedStocks.cost
                ownedshares = ownedStocks.quantity
            }
        }
        cell.shareValue.text = "Share Value: \(formatAsCurrency(dollarAmount: sharecurrentvalue))"
        sharechange = (sharecurrentvalue-sharepreviousvalue)/sharepreviousvalue
        if Float(sharechange) < 0 {
            cell.shareValue.textColor = UIColor.systemRed
        } else {
            cell.shareValue.textColor = UIColor.systemGreen
        }
        
        cell.shareQuantity.text = "Shares Owned: \(ownedshares)"
        
        
        
        // "https://storage.googleapis.com/iexcloud-hl37opg/api/logos/PETZ.png" //this is default logo
        let logo = logos[stock.symbol]
        var logoURLString = logo?.url ?? "https://media.baamboozle.com/uploads/images/407556/1624173273_168575_gif-url.gif"
        let logoURL = URL(string: logoURLString)!
        
        cell.stockLogo.af.setImage(withURL: logoURL)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

  
    var user: PFObject? = nil
    var ownedStock: PFObject? = nil
    var stocks: [StockInfo] = []
    var ownedStockArray = [OwnedStockInfo]()
    var logos: [String:Logo] = [:]
    

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!

    
    // Shows the error text (provided as a paramater) when called
    func showErrorText(_ errorText: String) {
        self.errorLabel.isHidden = false
        self.errorLabel.text = errorText
    }
    
    // Hides the error text when called
    func hideErrorText() {
        self.errorLabel.isHidden = true
        self.errorLabel.text = ""
    }
    
    // Updates the balance field when called
    func refreshBalance() {
        if self.user == nil {
            return
        }
        let balance = self.user?["balance"] as! Float
        let roundedBalance = round(balance * 100) / 100.0
        let formattedBalance = formatAsCurrency(dollarAmount: roundedBalance)
        balanceLabel.text = "Cash Balance: \(formattedBalance)"
        return
    }
    
    // Updates the portfolio value field when called
    func refreshPortfolioValue() {
        if self.user == nil {
            return
        }
        var totalvalue = 0.0 as Float
        for stock in self.stocks{
            for ownedStocks in self.ownedStockArray{
                if stock.symbol == ownedStocks.symbol{
                    totalvalue += stock.latestPrice * Float(ownedStocks.quantity)
                }
            }
        }
        let roundedPortfolioValue = round(totalvalue * 100) / 100.0
        let formattedPortfolioValue = formatAsCurrency(dollarAmount: roundedPortfolioValue)
        portfolioValueLabel.text = "Portfolio Value: \(formattedPortfolioValue)"
        return

    }
    
    func getStockInfo(successCallback: @escaping ([StockInfo]) -> ()) {
        // https://learnappmaking.com/urlsession-swift-networking-how-to/
          
        var stockResponseArray: [StockInfo] = []
            
        for ownedStock in self.ownedStockArray {
                let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(ownedStock.symbol)/quote?token=pk_246252e7872a41e4bb86d8c546d5e510")!
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
                        print(self.ownedStockArray.count)
                        print(stockResponseArray.count)
                        if self.ownedStockArray.count == stockResponseArray.count {
                            successCallback(stockResponseArray)
                            
                        }
                
                    } catch {
                        print("JSON error: \(error.localizedDescription)")
                    }
                }
                task.resume()
            }

        }
    
    
    // Formats float input as formatted string
    func formatAsCurrency(dollarAmount: Float) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let formatedNumber = numberFormatter.string(from: NSNumber(value: dollarAmount))
        
        return formatedNumber!
    }
    
    func queryOwnedStocks() {
        self.ownedStockArray.removeAll()
        var ownedStockList = [OwnedStockInfo]()
        let query = PFQuery(className: "Stock")
        query.whereKey("user", equalTo: user)
        query.findObjectsInBackground { [self] (objects: [PFObject]?, error: Error?) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let objects = objects {
                // The find succeeded.
                print("Successfully retrieved \(objects.count) stocks")
                for i in 0 ..< objects.count {
                    self.ownedStockArray.insert(OwnedStockInfo(symbol: objects[i]["symbol"] as! String, cost: objects[i]["amountSpent"] as! Float, quantity: objects[i]["quantityHeld"] as! Int), at: i)
                 
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "homeToBuySegue" {
            let destination = segue.destination as! TradeViewViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedStock = stocks[indexPath.row] as StockInfo
            destination.symbol = selectedStock.symbol
        }
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
    
    func handleStockInfo(stockArray: [StockInfo]) -> Void {
        stocks = stockArray
        getLogos()
        refreshBalance()
        refreshPortfolioValue()
        tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let user = PFUser.current()
        
        if user != nil {
            do {
                let query = try PFQuery.getUserObject(withId: user!.objectId!)
                self.user = query
            } catch {
                print(error)
            }
        }
        
        getStockInfo(successCallback: handleStockInfo)
        
        queryOwnedStocks()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        self.title = "Portfolio"
        // Check dark mode setting and set all views
        checkDarkMode()
        // Dark mode makes the text fields black
        
        // https://kaushalelsewhere.medium.com/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        
        view.addGestureRecognizer(tap)
   
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getStockInfo(successCallback: handleStockInfo)
        queryOwnedStocks()
        tableView.delegate = self
        tableView.dataSource = self

    }
    
    func checkDarkMode() {
        // add this code along with window code above to home view (initial view will set all views to dark/light)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate else { return }
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "darkMode") == true {
            delegate.window?.overrideUserInterfaceStyle = .dark
        } else {
            delegate.window?.overrideUserInterfaceStyle = .light
        }
    }

}
