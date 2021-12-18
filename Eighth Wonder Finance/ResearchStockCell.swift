//
//  ResearchStockCell.swift
//  Eighth Wonder Finance
//
//  Created by James Lipe on 10/27/21.
//

import UIKit

class ResearchStockCell: UITableViewCell {
    
    @IBOutlet weak var stockName: UILabel!
    @IBOutlet weak var currentPrice: UILabel!
    @IBOutlet weak var percentChange: UILabel!
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
