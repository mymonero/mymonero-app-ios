//
//  ConnectivityMessagePresentationController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/6/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
import ReachabilitySwift
//
class ConnectivityMessagePresentationController
{
	//
	// Static
	static let shared = ConnectivityMessagePresentationController()
	//
	// Properties
	var viewController: ConnectivityMessageViewController?
	var reachability = Reachability()!
	//
	fileprivate var _isTransitioningPresentation = false
	//
	// Lifecycle - Init
	required init()
	{
		self.setup()
	}
	func setup()
	{
		self.startObserving()
		// we do not appear to need to do this:
//		self._configurePresentationWithReachability()
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(reachabilityChanged),
			name: ReachabilityChangedNotification,
			object: self.reachability
		)
		do {
			try self.reachability.startNotifier()
		} catch let e {
			assert(false, "Unable to start notification with error \(e)")
		}
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		self.reachability.stopNotifier()
		NotificationCenter.default.removeObserver(
			self,
			name: ReachabilityChangedNotification,
			object: self.reachability
		)
	}
	//
	// Imperatives - Presentation
	func _configurePresentationWithReachability()
	{
		// commented for debug
		if self.reachability.isReachable { // There is apparently a bug appearing in iOS 10 simulated apps whereby reconnection is not detected ; https://github.com/ashleymills/Reachability.swift/issues/151
			self.__dismiss()
		} else {
			self.__present()
		}
	}
	func __present()
	{
		if self.viewController != nil {
			DDLog.Info("ConnectivityMessage", "Asked to \(#function) but already presented.")
			return // already presented
		}
		if self._isTransitioningPresentation {
			assert(false)
			return // already asked to present before this method could finish… odd… called after returning onto main thread?
		}
		self._isTransitioningPresentation = true
		DDLog.Info("ConnectivityMessage", "Presenting")
		let viewController = ConnectivityMessageViewController()
		self.viewController = viewController
		self.___present_tryToAddChildViewController_andFinish()
	}
	func ___present_tryToAddChildViewController_andFinish()
	{
		assert(self.viewController != nil, "self.viewController != nil")
		let viewController = self.viewController!
		//
		guard let window = UIApplication.shared.delegate!.window! else {
			DDLog.Info("ConnectivityMessage", "Waiting for window and/or parentViewController")
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute:
			{
				self.___present_tryToAddChildViewController_andFinish() // try again…
			})
			return // bail
		}
		DDLog.Info("ConnectivityMessage", "Actually presenting")
//		parentViewController.addChildViewController(viewController)
		window.addSubview(viewController.view)
		// ^-- I looked into making this a view instead of viewController but some odd delay in layout/presentation occurs… *shrug*
		self._isTransitioningPresentation = false
	}
	func __dismiss()
	{
		if self.viewController == nil {
			DDLog.Info("ConnectivityMessage", "Asked to \(#function) but not presented.")
			return
		}
		if self._isTransitioningPresentation {
			assert(false)
			return // already asked to present before this method could finish… odd… called after returning onto main thread?
		}
		self._isTransitioningPresentation = true
		DDLog.Info("ConnectivityMessage", "Dismissing")
//		self.viewController!.removeFromParentViewController()
		self.viewController!.view!.removeFromSuperview()
		self.viewController = nil
		self._isTransitioningPresentation = false
	}
	//
	// Delegation
	@objc func reachabilityChanged()
	{
		self._configurePresentationWithReachability()
	}
}
