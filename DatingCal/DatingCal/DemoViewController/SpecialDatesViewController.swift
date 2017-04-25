//
//  DemoViewController.swift
//  TestCollectionView
//
//  Created by Alex K. on 12/05/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit
import expanding_collection
import RealmSwift

class SpecialDatesViewController: ExpandingViewController {
  
    typealias ItemInfo = (imageName: String, title: String)
    fileprivate var cellsIsOpen = [Bool]()
//    fileprivate let items: [ItemInfo] = [("item0", "Boston"),("item1", "New York"),("item2", "San Francisco"),("item3", "Washington")]
    fileprivate var items: [EventModel] = [] {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
  
    @IBOutlet weak var pageLabel: UILabel!
}

// MARK: life cicle

extension SpecialDatesViewController {
  
  override func viewDidLoad() {
    itemSize = CGSize(width: 256, height: 335)
    super.viewDidLoad()
    
//    let realm = try! Realm()
//    self.items = Array(realm.object(ofType: SpecialDatesStorage.self, forPrimaryKey: 0)!.dates)
//    self.items = Array(realm.objects(EventModel.self).filter { $0.keyDateType != nil } )
    self.items = DatesGenerator.sharedInstance.generateDates(birthDate: Configurations.sharedInstance.birthDate()!, relationshipDate: Configurations.sharedInstance.relationshipDate()!)
    
    
    registerCell()
    fillCellIsOpeenArry()
    addGestureToView(collectionView!)
//    configureNavBar()
  }
}

// MARK: Helpers 

extension SpecialDatesViewController {
  
  fileprivate func registerCell() {
    
    let nib = UINib(nibName: String(describing: SpecialDatesCollectionViewCell.self), bundle: nil)
    collectionView?.register(nib, forCellWithReuseIdentifier: String(describing: SpecialDatesCollectionViewCell.self))
  }
  
  fileprivate func fillCellIsOpeenArry() {
    for _ in items {
      cellsIsOpen.append(false)
    }
  }
  
//  fileprivate func getViewController() -> ExpandingTableViewController {
//    let storyboard = UIStoryboard(storyboard: .Main)
//    let toViewController: DemoTableViewController = storyboard.instantiateViewController()
//    return toViewController
//  }
  
//  fileprivate func configureNavBar() {
//    navigationItem.leftBarButtonItem?.image = navigationItem.leftBarButtonItem?.image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
//  }
}

/// MARK: Gesture

extension SpecialDatesViewController {
  
  fileprivate func addGestureToView(_ toView: UIView) {
    let gesutereUp = Init(UISwipeGestureRecognizer(target: self, action: #selector(SpecialDatesViewController.swipeHandler(_:)))) {
      $0.direction = .up
    }
    
    let gesutereDown = Init(UISwipeGestureRecognizer(target: self, action: #selector(SpecialDatesViewController.swipeHandler(_:)))) {
      $0.direction = .down
    }
    toView.addGestureRecognizer(gesutereUp)
    toView.addGestureRecognizer(gesutereDown)
  }

  func swipeHandler(_ sender: UISwipeGestureRecognizer) {
    let indexPath = IndexPath(row: currentIndex, section: 0)
    guard let cell  = collectionView?.cellForItem(at: indexPath) as? SpecialDatesCollectionViewCell else { return }
    // double swipe Up transition
    if cell.isOpened == true && sender.direction == .up {
//      pushToViewController(getViewController())
      
//      if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
//        rightButton.animationSelected(true)
//      }
    }
    
    let open = sender.direction == .up ? true : false
    cell.cellIsOpen(open)
    cellsIsOpen[(indexPath as NSIndexPath).row] = cell.isOpened
  }
}

// MARK: UIScrollViewDelegate 

extension SpecialDatesViewController {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    pageLabel.text = "\(currentIndex+1)/\(items.count)"
  }
}

// MARK: UICollectionViewDataSource

extension SpecialDatesViewController {
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    guard let cell = cell as? SpecialDatesCollectionViewCell else { return }

    let index = (indexPath as NSIndexPath).row % items.count
    let info = items[index]
    cell.backgroundImageView?.image = UIImage(named: info.keyDateType ?? "Event")
    cell.customTitle.text = info.keyDateType
    cell.subTitle.text = dateFormatter.string(from: info.startDate!)
    cell.cellIsOpen(cellsIsOpen[index], animated: false)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? SpecialDatesCollectionViewCell
          , currentIndex == (indexPath as NSIndexPath).row else { return }

    if cell.isOpened == false {
      cell.cellIsOpen(true)
    } else {
//      pushToViewController(getViewController())
      
//      if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
//        rightButton.animationSelected(true)
//      }
    }
  }
}

// MARK: UICollectionViewDataSource
extension SpecialDatesViewController {
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SpecialDatesCollectionViewCell.self), for: indexPath)
  }
}
