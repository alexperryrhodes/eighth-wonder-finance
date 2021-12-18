//
//  SearchDataLoader.swift
//  Eighth Wonder Finance
//
//  Created by Joshua Harris on 11/7/21.
//

import Foundation

public class DataLoader {
    
    @Published var searchData = [String: Any]()
    
    init() {
        load()
    }
    
    func load() {
        
        if let fileLocation = Bundle.main.url(forResource: "search", withExtension: "json") {
            do {
                let data = try Data(contentsOf: fileLocation)
                let json = try? JSONSerialization.jsonObject(with: data, options:[])
                let dictionary = json as? [String: Any]
                self.searchData = dictionary!
            } catch {
                print(error)
            }
        }
    }
}

public class WatchList {
    
    @Published var defaultWatchList = [String]()
    
    init() {
        createWatchList()
    }
    
    func createWatchList() {
        self.defaultWatchList = ["MSFT", "AAPL", "AMZN", "GOOGL", "TSLA", "FB", "NVDA", "BRK.B",
            "JPM", "JNJ", "UNH", "HD", "PG", "V", "BAC", "ADBE", "MA", "NFLX", "DIS", "PFE"]
        
        let defaults = UserDefaults.standard
        defaults.set(defaultWatchList, forKey: "defaultWatchList")
    }
}
