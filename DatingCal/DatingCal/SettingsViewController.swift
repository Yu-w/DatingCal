//
//  SettingsViewController.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/23/17.
//
//

import Foundation
import UIKit
import DateTimePicker
import TextFieldEffects

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didClickDone(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
