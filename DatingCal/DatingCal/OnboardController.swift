//
//  OnboardViewController.swift
//  DatingCal
//
//  Created by Wang Yu on 4/30/17.
//
//

import Foundation
import Onboard

class OnboardController {
    
    static func generateOnboardingViewController(completion: @escaping () -> ()) -> OnboardingViewController {
        let onboardVC = OnboardingViewController(
            backgroundImage: #imageLiteral(resourceName: "onboard_bg"),
            contents: [
                firstPage(),
                secondPage(),
                thirdPage(),
                fourthPage()
            ])
        onboardVC?.shouldFadeTransitions = true
        onboardVC?.shouldMaskBackground = false
        onboardVC?.allowSkipping = true
        onboardVC?.skipButton.setTitle("Get started", for: .normal)
        onboardVC?.view.bringSubview(toFront: onboardVC!.skipButton)
        onboardVC?.skipHandler = {
            completion()
        }
        return onboardVC!
    }
    
    fileprivate static func configureContentPage(page: OnboardingContentViewController) {
        page.iconWidth = 326
        page.iconHeight = 580
        page.topPadding = 318
        page.underIconPadding = -832
        let bottomPanel = UIView()
        bottomPanel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        bottomPanel.frame = CGRect(x: 0, y: page.view.bounds.height - 44, width: page.view.bounds.width, height: 44)
        page.view.addSubview(bottomPanel)
    }
    
    fileprivate static func firstPage() -> OnboardingContentViewController {
        let page = OnboardingContentViewController(title: "Dating Cal", body: "A calendar designed for you and your loved ones", image: #imageLiteral(resourceName: "onboard_p1"), buttonText: nil) {
            
        }
        configureContentPage(page: page)
        return page
    }
    
    fileprivate static func secondPage() -> OnboardingContentViewController {
        let page = OnboardingContentViewController(title: "Discover", body: "Never forget those important dates for your loved ones", image: #imageLiteral(resourceName: "onboard_p2"), buttonText: nil) {
            
        }
        configureContentPage(page: page)
        return page
    }
    
    fileprivate static func thirdPage() -> OnboardingContentViewController {
        let page = OnboardingContentViewController(title: "Tips", body: "Get tips for the special date and surprise your loved ones", image: #imageLiteral(resourceName: "onboard_p3"), buttonText: nil) {
            
        }
        configureContentPage(page: page)
        return page
    }
    
    fileprivate static func fourthPage() -> OnboardingContentViewController {
        let page = OnboardingContentViewController(title: "Customizable", body: "Manage your own date and get reminded and organized", image: #imageLiteral(resourceName: "onboard_p4"), buttonText: nil) {
        }
        configureContentPage(page: page)
        return page
    }
    
}
