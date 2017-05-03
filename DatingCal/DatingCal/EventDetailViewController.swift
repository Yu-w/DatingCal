//
//  EventDetailViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/25/17.
//
//

import UIKit

class EventDetailViewController: UIViewController {
    @IBOutlet var eventDescription: UILabel?
    @IBOutlet var eventLocation: UILabel?
    @IBOutlet var eventTitle: UILabel?
    
    var eventToShow : EventModel? = nil {
        didSet {
            refresh()
        }
    }
    
    private func refresh() {
        eventTitle?.text = eventToShow?.summary ?? "(Not found)"
        eventLocation?.text = eventToShow?.location ?? "(no location)"
        eventDescription?.text = "UNDER CONSTRUCTION"
    }
    
    // Make sure to refresh after view shows up, in case IBOutlet references are wrong
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    @IBAction func willCloseWindow(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func willDeleteEvent(_ sender: Any) {
    }
    
}
