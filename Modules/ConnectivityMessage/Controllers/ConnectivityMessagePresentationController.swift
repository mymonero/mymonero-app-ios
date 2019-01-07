//
//  ConnectivityMessagePresentationController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/6/17.
//  Copyright (c) 2014-2019, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import UIKit
import Reachability
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
			name: Notification.Name.reachabilityChanged,
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
			name: Notification.Name.reachabilityChanged,
			object: self.reachability
		)
	}
	//
	// Imperatives - Presentation
	func _configurePresentationWithReachability()
	{
		// commented for debug
		if self.reachability.connection != .none { // There is apparently a bug appearing in iOS 10 simulated apps by which reconnection is not detected - https://github.com/ashleymills/Reachability.swift/issues/151 - this looks to be fixed in iOS 11 / Swift 4
			self.__dismiss()
		} else {
			self.__present()
		}
	}
	func __present()
	{
		if Thread.isMainThread == false {
			DispatchQueue.main.async { [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf.__present()
			}
			return
		}
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
		if Thread.isMainThread == false {
			DispatchQueue.main.async { [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf.__dismiss()
			}
			return
		}
		if self.viewController == nil {
//			DDLog.Info("ConnectivityMessage", "Asked to \(#function) but not presented.")
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
