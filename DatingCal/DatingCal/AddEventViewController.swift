//
//  AddEventViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/12/17.
//
//

import UIKit
import DateTimePicker
import TextFieldEffects

class AddEventViewController: UIViewController {

    @IBOutlet weak var titleTextField: HoshiTextField!
    @IBOutlet weak var descTextField: HoshiTextField!
    @IBOutlet weak var startTimeButton: UIButton!
    @IBOutlet weak var endTimeButton: UIButton!
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = " hh:mm a MMM dd, yyyy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.placeholder = "Title for the event"
        descTextField.placeholder = "Description for the event"

        startTimeButton.addTarget(self, action: #selector(self.invokePicker(sender:)), for: .touchUpInside)
        endTimeButton.addTarget(self, action: #selector(self.invokePicker(sender:)), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func invokePicker(sender: UIButton) {
        let picker = DateTimePicker.show(minimumDate: Date())
        picker.highlightColor = UIColor(red:0.99, green:0.32, blue:0.48, alpha:1.00)
        picker.completionHandler = { date in
            sender.setTitle(self.dateFormatter.string(from: date), for: .normal)
        }
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
