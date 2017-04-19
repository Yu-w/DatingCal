//
//  MainCalendarViewController
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit
import FSCalendar
import PromiseKit
import RealmSwift

class MainCalendarViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var eventsToPresent = [EventModel]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var selectedDate = Date() {
        didSet {
            self.calendar.select(self.selectedDate)
            let realm = try! Realm()
            self.eventsToPresent = realm.objects(EventModel.self).filter { (event) -> Bool in
                if let date = event.startDate {
                    return self.calendar.gregorian.isDate(date, inSameDayAs: self.selectedDate)
                } else if let date = event.startTime {
                    return self.calendar.gregorian.isDate(date, inSameDayAs: self.selectedDate)
                } else {
                    return false
                }
            }
        }
    }
    
    /// lazy initializaed date formatter for converting date formats
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    /// pan gesture recognizer for capturing swipe behavior
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    /// set status bar to white color
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNeedsStatusBarAppearanceUpdate()

        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        self.view.addGestureRecognizer(self.scopeGesture)
        self.addButton.layer.cornerRadius = self.addButton.layer.bounds.width / 2

        calendarViewSetup()
        tableViewSetup()

        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedDate = Date()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // These lines ensure that the user is logged in
        //   and that his or her calendar has been synchronized
        appDelegate.googleClient.ensureLogin(presenter: self).then { x -> Promise<Void> in
            return self.appDelegate.googleCalendar.loadAll()
        }.then { x -> Promise<String> in
            debugPrint("Sign In finished.")
            return self.appDelegate.googleClient.userId
        }.then { userId -> Void in
            debugPrint("Google OAuth2 User ID = " + userId)
            Configurations.sharedInstance.currentIdString = userId
            if Configurations.sharedInstance.birthDate(id: userId) == nil
                || Configurations.sharedInstance.relationshipDate(id: userId) == nil {
                self.performSegue(withIdentifier: "goSetup", sender: self)
            }
        }.catch { err -> Void in
            debugPrint("ERROR during Sign In: ", err)
            // TODO: provide a retry button
        }
    }
    
    /// calendar setup
    func calendarViewSetup() {
        self.calendar.scope = .month
        self.calendar.backgroundColor = .clear
        self.calendar.bottomBorder.alpha = 0
        
    }
    
    /// table setup
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
