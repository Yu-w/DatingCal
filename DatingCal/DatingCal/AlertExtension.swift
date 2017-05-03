//
//  AlertExtension.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/19/17.
//
//

import Foundation
import PromiseKit
import UIKit

extension UIViewController {
    /// An extension to simply the showing of alert dialogs
    /// Code written by Yu Wang. Separated as extension by Mark Yu.
    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Done", style: .default))
        self.present(alertVC, animated: true)
    }
}

class UIViewControllerWithWaitAlerts : UIViewController {
    
    private var alertPleaseWait : UIAlertController?
    
    func showPleaseWait() {
        if alertPleaseWait != nil {
            return
        }
        let alertVC = UIAlertController(title: "Please wait...", message: nil, preferredStyle: .alert)
        self.present(alertVC, animated: true)
        alertPleaseWait = alertVC
    }
    
    func hidePleaseWait() -> Promise<Void> {
        guard let alert = alertPleaseWait else {
            return Promise(value: ())
        }
        return Promise<Void>{ fulfill, reject in
            alert.dismiss(animated: true, completion: {x in fulfill()})
            alertPleaseWait = nil
        }
    }
    
}
