//
//  EventDetailViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/25/17.
//
//

import UIKit
import SwiftDate

class EventDetailViewController: UIViewControllerWithWaitAlerts {
    @IBOutlet var eventDescription: UILabel?
    @IBOutlet var eventLocation: UILabel?
    @IBOutlet var eventTitle: UILabel?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var _eventToShow: EventModel? = nil
    var eventToShow : EventModel? {
        get {
            return _eventToShow
        }
        set {
            _eventToShow = newValue
            refresh()
        }
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
        if eventToShow == nil {
            // Don't show the prompt if the event doesn't exist
            return
        }
        let alertVC = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: self.willReallyDeleteEvent))
        alertVC.addAction(UIAlertAction(title: "No", style: .default))
        self.present(alertVC, animated: true)
    }
    
    // ------------- private helper functions
    
    private func refresh() {
        eventTitle?.text = eventToShow?.summary ?? "(Not found)"
        eventLocation?.text = ""
        if let location = eventToShow?.location, location != "" {
            eventLocation?.text = "Location: " + location
        }
        eventDescription?.text = eventToShow?.describe() ?? ""
    }
    
    private func willReallyDeleteEvent(_ sender: UIAlertAction) {
        guard let eventId = self.eventToShow?.id
            , let calendarId = self.eventToShow?.calendar.first?.id else {
            return
        }
        self.showPleaseWait()
        self._eventToShow = nil
        _ = self.appDelegate.googleCalendar.deleteEvent(eventId,
                                                        calendarId).catch { err in
            _ = self.hidePleaseWait().then {
                self.showAlert("Failed to delete events", err.localizedDescription)
            }
        }.then { _ -> Void in
            _ = self.hidePleaseWait().then {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
