//
//  DatesSetupViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/16/17.
//
//

import UIKit
import SwiftDate
import PromiseKit
import RealmSwift

class DatesSetupViewController: UIViewController {

    @IBOutlet weak var firstDatePicker: UIDatePicker!
    @IBOutlet weak var secondDatePicker: UIDatePicker!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstDatePicker.timeZone = TimeZone.current
        firstDatePicker.calendar = Calendar.current
        secondDatePicker.timeZone = TimeZone.current
        secondDatePicker.calendar = Calendar.current
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneButtonDidClicked(_ sender: UIButton) {
        let birthDate = firstDatePicker.date
        let relationshipDate = secondDatePicker.date
        let events = DatesGenerator.sharedInstance.generateDates(birthDate: birthDate, relationshipDate: relationshipDate)
        self.appDelegate.googleCalendar.ensureOurCalendar().then { _ -> Promise<[ThreadSafeEvent]> in
            return when(fulfilled: events.map { event -> Promise<ThreadSafeEvent> in
                return self.appDelegate.googleCalendar.createEvent(event)
            })
        }.then { createdEvents -> Void in
            self.dismiss(animated: true, completion: nil)
        }.catch { err in
            self.showAlert("Error", "Cannot create events. Reason: " + err.localizedDescription)
        }
        Configurations.sharedInstance.setBirthDate(date: birthDate)
        Configurations.sharedInstance.setRelationshipDate(date: relationshipDate)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
