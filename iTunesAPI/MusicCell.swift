//
//  MusicCell.swift
//  testItunesApi
//
//  Created by Sergey Kopytov on 26.02.2018.
//  Copyright © 2018 Sergey Kopytov. All rights reserved.
//

import UIKit
import ESTMusicIndicator

class MusicCell: UITableViewCell {
    
    @IBOutlet weak var indicator: ESTMusicIndicatorView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        indicator.tintColor = .orange
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        //super.setSelected(false, animated: true)
        // Configure the view for the selected state
    }

}
