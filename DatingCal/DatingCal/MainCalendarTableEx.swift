//
//  MainCalendarTableEx.swift
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit

extension MainCalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK:- UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventsToPresent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MainCalendarEventTableViewCell", for: indexPath
            ) as! MainCalendarEventTableViewCell
        cell.configureData(event: eventsToPresent[indexPath.row], color: nil)
        return cell
    }
    
    // MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    /// animate the deselection of the selection of rows
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// force table section background as white
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor.white
    }
    
}
