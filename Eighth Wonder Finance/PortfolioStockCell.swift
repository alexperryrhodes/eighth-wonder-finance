//
//  PortfolioStockCell.swift
//  Eighth Wonder Finance
//
//  Created by Adrian Lujo on 11/20/21.
//

import UIKit

class PortfolioStockCell: UITableViewCell {

    @IBOutlet weak var stockName: UILabel!
    @IBOutlet weak var shareQuantity: UILabel!
    @IBOutlet weak var shareValue: UILabel!
    @IBOutlet weak var stockLogo: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        stockLogo.layer.masksToBounds = true
        stockLogo.layer.cornerRadius = stockLogo.frame.size.width / 2
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
