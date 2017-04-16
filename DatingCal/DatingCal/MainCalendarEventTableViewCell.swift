//
//  MainCalendarEventTableViewCell.swift
//  DatingCal
//
//  Created by Wang Yu on 4/12/17.
//
//

import UIKit

class MainCalendarEventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leftBarView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    func configureData(event: EventModel, color: UIColor?) {
        self.titleLabel.text = event.summary
        self.descLabel.text = event.desc
        if let color = color {
            self.leftBarView.backgroundColor = color
            self.timeLabel.textColor = color
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
