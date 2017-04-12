//
//  MainCalendarViewController
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit
import FSCalendar

class MainCalendarViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    var selectedDate = Date()
    var tableRows = 0
    
    // lazy initializaed date formatter for converting date formats
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    // pan gesture recognizer for capturing swipe behavior
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        self.view.addGestureRecognizer(self.scopeGesture)
        
        calendarViewSetup()
        tableViewSetup()
        
        // test select date
        let nextDat = self.calendar.gregorian.date(byAdding: Calendar.Component.day, value: 3, to: Date())
        self.calendar.select(nextDat)

        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableRows = 0
    }
    
    // calendar setup
    func calendarViewSetup() {
        self.calendar.scope = .month
        self.calendar.backgroundColor = .clear
        self.calendar.bottomBorder.alpha = 0
        
    }
    
    // table setup
    func tableViewSetup() {
        self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.tableFooterView = UIView()
    }

    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            // change calendar mode when swipe vertically
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
}
