//
//  DemoCollectionViewCell.swift
//  TestCollectionView
//
//  Created by Alex K. on 12/05/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit
import expanding_collection

class SpecialDatesCollectionViewCell: BasePageCollectionCell {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var customTitle: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var backSummaryLabel: UILabel!
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        customTitle.layer.shadowRadius = 2
        customTitle.layer.shadowOffset = CGSize(width: 0, height: 3)
        customTitle.layer.shadowOpacity = 0.2
        
        subTitle.layer.shadowRadius = 2
        subTitle.layer.shadowOffset = CGSize(width: 0, height: 3)
        subTitle.layer.shadowOpacity = 0.2
    }
    
    func configureCell(event: EventModel) {
        backgroundImageView.image = UIImage(named: event.keyDateType ?? "Event")
        customTitle.text = event.keyDateType
        subTitle.text = dateFormatter.string(from: event.startDate!)
        backSummaryLabel.text = event.summary
    }
    
}
