//
//  DatesSetupViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/16/17.
//
//

import UIKit

class DatesSetupViewController: UIViewController {

    @IBOutlet weak var firstDatePicker: UIDatePicker!
    @IBOutlet weak var secondDatePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstDatePicker.timeZone = TimeZone.ReferenceType.local
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
        print(birthDate)
        let relationshipDate = secondDatePicker.date
        let events = DatesGenerator.sharedInstance.generateDates(birthDate: birthDate, relationshipDate: relationshipDate)
        self.dismiss(animated: true, completion: nil)
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
