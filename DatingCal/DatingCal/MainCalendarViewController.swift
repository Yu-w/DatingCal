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

class MainCalendarViewController: UIViewControllerWithWaitAlerts, UIGestureRecognizerDelegate {
    
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
                return event.shouldShowAtDate(self.selectedDate, self.calendar.gregorian)
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
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        
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
    }
    
    private let sequentialLogin = SequentialPromise<Void>()
    private let realmProvider = BusinessRealmProvider()
    var hasLoggedIn = false
    
    override func viewDidAppear(_ animated: Bool) {
        // These lines ensure that the user is logged in
        //   and that his or her calendar has been synchronized
        if self.hasLoggedIn {
            return
        }
        _ = sequentialLogin.neverAppend {
            return self.appDelegate.googleClient.ensureLogin(presenter: self)
                .then { x -> Promise<Void> in
                    self.showPleaseWait()
                    return self.appDelegate.googleCalendar.loadAll()
                }.then { x -> Void in
                    debugPrint("Sign In finished.")
                    let userId = UserModel.getPrimaryUser(self.realmProvider)!.id
                    debugPrint("Google OAuth2 User ID = " + userId)
                    
                    Configurations.sharedInstance.currentIdString = userId
                    if Configurations.sharedInstance.birthDate(id: userId) == nil
                        || Configurations.sharedInstance.relationshipDate(id: userId) == nil {
                        self.performSegue(withIdentifier: "goSetup", sender: self)
                    }
                    self.hasLoggedIn = true
                }.catch { err -> Void in
                    debugPrint("ERROR during Sign In: ", err)
                    self.showAlert("Error", "Cannot Login. Please re-enter the app. Reason: " + err.localizedDescription)
                    // TODO: provide a retry button
                }.always {
                    self.hidePleaseWait()
                    self.selectedDate = Date()
            }
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
