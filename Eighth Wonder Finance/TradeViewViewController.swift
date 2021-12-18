//
//  TradeViewViewController.swift
//  Eighth Wonder Finance
//
//  Created by Joshua Harris on 10/27/21.
//

import UIKit
import Parse

class TradeViewViewController: UIViewController, UITextFieldDelegate {
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
    
    
    // Variable that represents the current state of the buy/sell segment control
    enum TradeState {
        case buy
        case sell
    }
    
    var tradeState: TradeState {
        if tradeSegmentControl.selectedSegmentIndex == 0 {
            return TradeState.buy
        } else {
            return TradeState.sell
        }
    }

    
    var numberOfShares: Int = 0
    var sharePrice: Float = 0
    var symbol: String = "MSFT"
    var user: PFObject? = nil
    var ownedStock: PFObject? = nil
    var quantityHeld: Int = 0
    var ownedStockBool: Bool = false
    

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var tradeSegmentControl: UISegmentedControl!
    @IBOutlet weak var symbolLabel: UILabel!
    
    @IBOutlet weak var numberOfSharesOwnedValue: UILabel!
    
    @IBOutlet weak var numberOfSharesLabel: UILabel!
    @IBOutlet weak var numberOfSharesInput: UITextField!
    
    @IBOutlet weak var shareDisplayLabel: UILabel!
    @IBOutlet weak var shareDisplayValueLabel: UILabel!
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var totalPriceValueLabel: UILabel!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    
    // Determines if Confirm button begins buy or sell functionalty
    @IBAction func onConfirm(_ sender: Any) {
        if tradeState == .buy {
            self.onBuyConfirm(sender)
        } else {
            self.onSellConfirm(sender)
        }
    }
    
    
    // Sell functionality: updates qualtity help and balance
    func onSellConfirm(_ sender: Any) {
        hideErrorText()
        
        //If user does not own stock, display error message
        if ownedStockBool == false {
            self.showErrorText("You do not own this stock")
            print("Error: Use does not own any stocks of this symbol")
            
        } else if ownedStockBool == true {
            
            // If the number of shares the user is trying to sell is greater than what they own
            // Let them sell only as many as they own
            // Show error message
            if self.numberOfShares > quantityHeld {
                self.numberOfShares = quantityHeld
                self.showErrorText("You own \(quantityHeld) shares of \(symbol). Only \(quantityHeld) shares sold.")
            }
            self.ownedStock?["quantityHeld"] = self.quantityHeld - self.numberOfShares
            self.ownedStock?["amountSold"] = self.ownedStock?["amountSold"] as! Int + self.numberOfShares
            ownedStock?.saveInBackground { (success, error) in
                if (success) {
                    let totalPrice = Float(self.numberOfShares) * self.sharePrice
                    let roundedPrice = round(totalPrice * 100) / 100.0
                    let startBalance = self.user!["balance"] as! Float
                    self.user!["balance"] = startBalance + roundedPrice
                    self.user?.saveInBackground { (sucess, error) in
                        if (success) {
                            print("User saved")
                            self.refreshBalance()
                            self.queryOwnedStocks()
                            self.numberOfSharesOwnedValue.text = "\(self.quantityHeld)"
                            self.clearTextField()
                        } else {
                            print(error?.localizedDescription ?? "Unknown Error")
                        }
                    }
                } else {
                    print(error?.localizedDescription ?? "Unknown Error")
                }
            }
        }
    }
    
    
    // APR: Need to add funtionality to prevent buys when price per stock = $0
    // Buy functionality:
    func onBuyConfirm(_ sender: Any) {
        hideErrorText()
        let totalPrice = Float(numberOfShares) * sharePrice
        let roundedPrice = round(totalPrice * 100) / 100.0
        let query = PFQuery(className: "Stock")
        let startBalance = self.user!["balance"] as! Float
        if startBalance - roundedPrice < 0 {
            self.showErrorText("You don't have enough money to buy \(numberOfShares) shares of this stock")
            return
        }
        query.whereKey("user", equalTo: user)
        query.whereKey("symbol", equalTo: symbol)
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let objects = objects {
                // The find succeeded.
                print("Successfully retrieved \(objects.count) stocks.")
                // Do something with the found objects
                if objects.count == 0 {
                    let stock = PFObject(className: "Stock")
                    stock["symbol"] = self.symbol
                    stock["quantityHeld"] = self.numberOfShares
                    stock["amountSpent"] = roundedPrice
                    stock["user"] = self.user
                    stock.saveInBackground { (success, error) in
                        if (success) {
                            self.user!["balance"] = startBalance - roundedPrice
                            self.user!.add(stock, forKey: "stocks")
                            self.user?.saveInBackground { (sucess, error) in
                                if (success) {
                                    print("User saved")
                                    self.refreshBalance()
                                    self.queryOwnedStocks() //Added APR
                                } else {
                                    print(error?.localizedDescription)
                                }
                            }
                        } else {
                            print(error?.localizedDescription)
                        }
                    }
                } else if objects.count == 1 {
                    let stockToUpdate = objects[0]
                    stockToUpdate["quantityHeld"] = stockToUpdate["quantityHeld"] as! Int + self.numberOfShares
                    stockToUpdate["amountSpent"] = stockToUpdate["amountSpent"] as! Float + roundedPrice
                    stockToUpdate.saveInBackground { (success, error) in
                        if (success) {
                            let startBalance = self.user!["balance"] as! Float
                            self.user!["balance"] = startBalance - roundedPrice
                            self.user?.saveInBackground { (sucess, error) in
                                if (success) {
                                    print("User saved")
                                    self.refreshBalance()
                                    self.queryOwnedStocks() //Added APR
                                } else {
                                    print(error?.localizedDescription)
                                }
                            }
                        } else {
                            print(error?.localizedDescription)
                        }
                    }
                } else {
                    print("Some error, user has two or more stocks of the same symbol")
                }
            }
        }
    }
    
    // Updates/clears various fields based on segment control
    @IBAction func tradeActionContol(_ sender: Any) {
        if tradeState == .buy {
            totalPriceLabel.text = "Total purchase price:"
            numberOfSharesLabel.text = "# of shares to buy:"
            hideErrorText()
            clearTextField()
            formatBuyButton()
        } else {
            totalPriceLabel.text = "Total sale price:"
            numberOfSharesLabel.text = "# of shares to sell:"
            hideErrorText()
            clearTextField()
            formatSellButton()
        }
    }
    
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
        balanceLabel.text = "Balance: \(formattedBalance)"
    }
    
    // Empties text Field
    func clearTextField() {
        numberOfSharesInput.text = "0"
    }

    
    // ???
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == numberOfSharesInput{
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    
    // Updates the total price field to reflect # shares x price per share
    func handleQuantityChange() {
        let totalPrice = Float(self.numberOfShares) * self.sharePrice
        let roundedPrice = round(totalPrice * 100) / 100
        let formattedPrice = formatAsCurrency(dollarAmount: roundedPrice)
        totalPriceValueLabel.text = "\(formattedPrice)"
    }
    
    
    // If quantity is chaged, call handleQuantityChange()
    @IBAction func onShareQuantityChange(_ sender: Any) {
        let nShares: Int? = Int(numberOfSharesInput.text!)
        if nShares != nil {
            self.numberOfShares = nShares!
            handleQuantityChange()
        }
    }
    
    
    // Updates the price per share label
    func handleStockInfo(stockArray: StockInfo) -> Void {
        sharePrice = stockArray.latestPrice
        let roundedPrice = round(sharePrice * 100) / 100
        let formattedPrice = formatAsCurrency(dollarAmount: roundedPrice)
        shareDisplayValueLabel.text = "\(formattedPrice)"
    }
    
    
    // Checks wether user owns stock, if so updates ownedStock bool and quantityHeld variable
    func queryOwnedStocks() {
        let query = PFQuery(className: "Stock")
        query.whereKey("user", equalTo: user)
        query.whereKey("symbol", equalTo: symbol)
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let objects = objects {
                // The find succeeded.
                print("Successfully retrieved \(objects.count) stocks")
                // If objects count = 0, stock is not currently owned by current user
                if objects.count == 0 {
                    self.numberOfSharesOwnedValue.text = "0"
                    self.ownedStockBool = false
                    // If objects count = 1, stock is currently owned by current user or was previous owned and sold
                } else if objects.count == 1 {
                    self.ownedStock = objects[0]
                    if let quantityHeld = objects[0]["quantityHeld"] as? Int {
                        self.quantityHeld = quantityHeld
                        self.numberOfSharesOwnedValue.text = "\(self.quantityHeld )"
                    }
                    // If the current qualtity held is >= 1 the stock is owned
                    if self.quantityHeld >= 1 {
                        self.ownedStockBool = true
                        // If the current qualtity held is <=1 the stock has been owned in the past is now not owned
                    } else {
                        self.ownedStockBool = false
                    }
                }
            }
        }
    }
    
    // Calls the API to get stock information
    func getStockQuote(successCallback: @escaping (StockInfo) -> ()) {
        // https://learnappmaking.com/urlsession-swift-networking-how-to/
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=pk_246252e7872a41e4bb86d8c546d5e510")!
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
                successCallback(stockResponse)
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
        }
        task.resume()
    }
    
    
    // Formats float inpuy as formatted string
    func formatAsCurrency(dollarAmount: Float) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let formatedNumber = numberFormatter.string(from: NSNumber(value: dollarAmount))
        
        return formatedNumber!
    }
    
    
    func formatBuyButton() {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]

        let buyAttributedString = NSAttributedString(string: "Confirm Buy", attributes: attributes)
       
        confirmButton.setAttributedTitle(buyAttributedString, for: .normal)
    }
    
    func formatSellButton() {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        let sellAttributedString = NSAttributedString(string: "Confirm Sell", attributes: attributes)
        confirmButton.setAttributedTitle(sellAttributedString, for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // keep text box white with black text in dark mode
        numberOfSharesInput.backgroundColor = .white
        numberOfSharesInput.textColor = .black
        self.numberOfSharesInput.delegate = self
    
        self.symbolLabel.text = self.symbol
        
        self.errorLabel.isHidden = true
    }
    
    
    // We need to update the balance every time the view appears
    override func viewDidAppear(_ animated: Bool) {
        let user = PFUser.current()
        
        if user != nil {
            do {
                let query = try PFQuery.getUserObject(withId: user!.objectId!)
                self.user = query
            } catch {
                print(error)
            }
        }
        if symbol != "" {
            getStockQuote(successCallback: handleStockInfo)
        }
        
        refreshBalance()
        queryOwnedStocks()
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
