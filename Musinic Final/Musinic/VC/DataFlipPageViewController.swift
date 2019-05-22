//
//  DataFlipPageViewController.swift
//  Musinic
//
//  Created by Student on 4/22/19.
//  Copyright © 2019 Student. All rights reserved.
//

import UIKit

let changeViewNotification = NSNotification.Name("changeViewNotification")

class DataFlipPageViewController: UIPageViewController
{
    // set up array with 2 pages to flip
    fileprivate lazy var pages: [UIViewController] = {
        return [
            self.getViewController(withIdentifier: "SearchViewController"),
            self.getViewController(withIdentifier: "DataViewController")
            
        ]
    }()
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    //Change view controller to the other page
    @objc func changeView(notification:Notification){
        if (notification.userInfo?["data"] as? String) != nil{
            DataInfo.shared.songName = notification.userInfo?["data"] as! String
            print(DataInfo.shared.songName)
        }
        if let firstVC = pages.last
        {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
            
        }
        let nc = NotificationCenter.default
        nc.post(name: renewSearchNotification, object: self, userInfo:nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate   = self
        
        if let firstVC = pages.first
        {
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
        }
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(changeView), name: changeViewNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func setDataViewController(){
        if let firstVC = pages.last
        {
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
        }
    }
}

extension DataFlipPageViewController: UIPageViewControllerDataSource
{
    //Compare the index of the controller so it doesn't get out of range
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0          else { return nil }
        
        guard pages.count > previousIndex else { return nil        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else { return nil }
        
        guard pages.count > nextIndex else { return nil         }
        
        return pages[nextIndex]
    }
}

extension DataFlipPageViewController: UIPageViewControllerDelegate { }
