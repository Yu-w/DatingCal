//
//  AlertExtension.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/19/17.
//
//

import Foundation
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
