//
//  TableViewCell.swift
//  DatingCal
//
//  Created by Wang Yu on 4/12/17.
//
//

import UIKit
import DZNEmptyDataSet

extension MainCalendarViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No event at \(self.dateFormatter.string(from: self.selectedDate))"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Tap the button below to add event."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "calendar")
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        let str = "Add Event"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.callout)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTap button: UIButton) {
        let alertVC = UIAlertController(title: "Event Added!", message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Test", style: .default))
        self.tableRows += 1
        self.tableView.reloadData()
        self.present(alertVC, animated: true)
    }
    
}
