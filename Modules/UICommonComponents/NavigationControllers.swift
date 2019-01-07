//
//  NavigationControllers.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/28/18.
//  Copyright © 2019 MyMonero. All rights reserved.
//

import UIKit

// SwipeableNavigationController inspired by https://stackoverflow.com/a/43433530/122115

extension UICommonComponents
{
	struct NavigationControllers
	{
		class SelfDelegatingNavigationController: UINavigationController, UINavigationControllerDelegate
		{
			//
			// Lifecycle
			override init(rootViewController: UIViewController)
			{
				super.init(rootViewController: rootViewController)
			}
			override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
			{
				super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
				self.delegate = self
			}
			required init?(coder aDecoder: NSCoder)
			{
				super.init(coder: aDecoder)
				self.delegate = self
			}
			deinit
			{
				delegate = nil
			}
		}
		class SwipeableNavigationController: SelfDelegatingNavigationController, UIGestureRecognizerDelegate
		{
			//
			// Properties
			fileprivate var duringPushAnimation = false
			//
			// Lifecycle
			deinit
			{
				self.interactivePopGestureRecognizer?.delegate = nil
			}
			//
			// Overrides - NavigationController
			override func pushViewController(_ viewController: UIViewController, animated: Bool)
			{
				duringPushAnimation = true
				//
				super.pushViewController(viewController, animated: animated)
			}
			//
			// Delegation - View visibility
			override func viewDidLoad()
			{
				super.viewDidLoad()
				//
				self.interactivePopGestureRecognizer?.delegate = self // This needs to be in here, not in init
			}
			//
			// Delegation - UINavigationControllerDelegate
			func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
				guard let swipeableNavigationController = navigationController as? SwipeableNavigationController else {
					return
				}
				swipeableNavigationController.duringPushAnimation = false
			}
			//
			// Delegation - UIGestureRecognizerDelegate
			func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
				guard gestureRecognizer == interactivePopGestureRecognizer else {
					return true // default value
				}
				// Disable pop gesture in two situations:
				// 1) when the pop animation is in progress
				// 2) when user swipes quickly a couple of times and animations don't have time to be performed
				return viewControllers.count > 1 && duringPushAnimation == false
			}
		}
	}
}
