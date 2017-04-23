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
    var startTime: Date?
    var endTime: Date?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = " hh:mm a MMM dd, yyyy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.placeholder = "Title for the event"
        descTextField.placeholder = "Description (optional)"

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
            if sender.tag == 1 {
                self.startTime = date
            } else if sender.tag == 2 {
                self.endTime = date
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        titleTextField.resignFirstResponder()
        descTextField.resignFirstResponder()
    }
    
    @IBAction func doneButtonDidClicked(_ sender: UIButton) {
        if let startTime = self.startTime, let endTime = self.endTime, let title = titleTextField.text {
            let event = EventModel()
            event.summary = title
            event.desc = (descTextField.text) ?? ""
            event.startTime = startTime
            event.endTime = endTime
            appDelegate.googleCalendar.createSingleEvent(event).then { _ in
                self.dismiss(animated: true, completion: nil)
            }.catch { err in
                self.showAlert("Error", "Cannot create event. Reason: " + err.localizedDescription)
            }
        } else {
            showAlert("Warning", "Please fill title, start time, and end time before submitting!")
        }
    }
    
    @IBAction func closeButtonDidClicked(_ sender: UIButton) {
        print("*a")
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
