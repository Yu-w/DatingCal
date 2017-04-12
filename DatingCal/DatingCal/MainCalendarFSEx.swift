//
//  MainCalendarFSEx.swift
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit
import FSCalendar

extension MainCalendarViewController: FSCalendarDataSource, FSCalendarDelegate {
    
    // Update calendar view when layout changes
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    // Handler for selecting dates
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        debugPrint("did select date \(self.dateFormatter.string(from: date))")
        let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        debugPrint("selected dates is \(selectedDates)")
        if monthPosition == .next || monthPosition == .previous {
            calendar.setCurrentPage(date, animated: true)
        }
    }
    
    // Handler for calendar page switching
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        debugPrint("\(self.dateFormatter.string(from: calendar.currentPage))")
    }
    
}
