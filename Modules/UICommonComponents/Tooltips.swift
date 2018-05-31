//
//  Tooltips.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/7/17.
//  Copyright (c) 2014-2018, MyMonero.com
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
import Foundation
import AMPopTip

extension UICommonComponents
{
	class TooltipSpawningLinkButtonView: UICommonComponents.LinkButtonView
	{
		//
		// Constants
		static let usabilityExpanded_w: CGFloat = 30
		static let usabilityExpanded_h: CGFloat = 32
		static let tooltip_maxWidth: CGFloat = 230 - 12 // seems to be asking for the text width instead,  -k
		//		let maxWidth: CGFloat = 230
		//		appearance.maxWidth = maxWidth
		static let tooltipLabelSqueezingVisualMarginReductionConstant_x: CGFloat = 4
		//
		// Properties
		var tooltipText: String
		var tip: PopTip?
		//
		var tooltipDirectionFromOrigin: PopTipDirection = .up // settable by instantiator
		var willPresentTipView_fn: (() -> Void)?
		//
		// Lifecycle - Init
		init(tooltipText: String) {
			self.tooltipText = tooltipText
			super.init(
				mode: .mono_default,
				size: .normal,
				title: NSLocalizedString("?", comment: "")
			)
			self.setup()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		func setup()
		{
			self.startObserving()
		}
		func startObserving()
		{
			// interactions
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
			//
			// self observing parent view visibility changes requires that the instantiator of self ensure that it calls the parentViewWillDisappear(animated:) method on self
			//
			// For delete everything, idle, lock-down, etc
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(willDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			//
			NotificationCenter.default.addObserver(self, selector: #selector(MMApplication_didSendEvent(_:)), name: MMApplication.NotificationNames.didSendEvent.notificationName, object: nil)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(UIApplicationWillChangeStatusBarFrame),
				name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
				object: nil
			)
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
			self._dismiss(dismissEvenIfCurrentlyAnimating: true) // just in case
			self.stopObserving()
		}
		func stopObserving()
		{
			NotificationCenter.default.removeObserver(
				self,
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			//
			NotificationCenter.default.removeObserver(self, name: MMApplication.NotificationNames.didSendEvent.notificationName, object: nil)
			NotificationCenter.default.removeObserver(
				self,
				name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
				object: nil
			)
		}
		//
		// Imperatives - Presentation
		var _isPresenting = false
		func _present()
		{
			if self.tip != nil {
				return
			}
			if self._isPresenting {
				return
			}
			self._isPresenting = true
			let tip = PopTip()
			do {
				tip.font = .middlingRegularSansSerif
				tip.textColor = UIColor(rgb: 0x161416)
				tip.bubbleColor = UIColor(rgb: 0xFCFBFC)
				tip.cornerRadius = 5
				tip.borderColor = UIColor(rgb: 0xFFFFFF)
				tip.borderWidth = 1/UIScreen.main.scale // single pixel / hairline
				tip.textAlignment = .left
				tip.edgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
				tip.edgeMargin = 4 // if needed
				tip.arrowSize = CGSize(width: 15, height: 13)
				tip.offset = self.tooltipDirectionFromOrigin == .left || self.tooltipDirectionFromOrigin == .right ? -6 : -7 // from arrow to the spawn origin - so that the actual visual offset ends up being 3
				//
				tip.shouldDismissOnTap = false // we'll observe other events - do not want conflict
			}
			self.tip = tip
			let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController! // not the WindowController.presentModalsInViewController, b/c we want these to be over the entire app window
			var inViewController: UIViewController = rootViewController
			while inViewController.presentedViewController != nil { // 'while' necessary rather than 'if'?
				inViewController = inViewController.presentedViewController!
			}
			let inView = inViewController.view!
			//
			let generator = UINotificationFeedbackGenerator()
			generator.prepare()
			generator.notificationOccurred(.warning) // TODO: are these feedback generator and note type appropriate?
			//
			tip.show(
				text: self.tooltipText,
				direction: self.tooltipDirectionFromOrigin,
				maxWidth: type(of: self).tooltip_maxWidth,
				in: inView,
				from: inView.convert(self.frame, from: self.superview)
			)
			if let fn = self.willPresentTipView_fn {
				fn()
			}
			tip.appearHandler =
			{ [unowned self] popTip in
				if popTip == self.tip {
					self._isPresenting = false
				} else {
					DDLog.Warn("UICommonComponents.Tooltips", "dismissHandler called but self.tip different from callback popTip. self._isPresenting is currently \(self._isPresenting).")
				}
			}
			tip.dismissHandler =
			{ [unowned self] popTip in
				if self.tip == nil {
					DDLog.Warn("UICommonComponents.Tooltips", "dismissHandler called but self.tip already nulled")
					return
				}
				if popTip == self.tip {
					self.tip = nil // if tip is still around, may as well release it
				} else {
					DDLog.Warn("UICommonComponents.Tooltips", "dismissHandler called but self.tip different from callback popTip")
				}
			}
		}
		func _dismiss(dismissEvenIfCurrentlyAnimating: Bool = true)
		{
			if self.tip == nil {
				return
			}
			self.tip!.hide(forced: dismissEvenIfCurrentlyAnimating)
		}
		//
		// Delegation - Interactions
		@objc func tapped()
		{
			if self.tip != nil {
				self._dismiss(dismissEvenIfCurrentlyAnimating: false) // false b/c else they can tap twice and it'll just appear to cancel animations and instantly disappear
				return
			}
			self._present()
		}
		//
		// Delegation - Notifications
		@objc func willDeconstructBootedStateAndClearPassword()
		{
			self._dismiss(dismissEvenIfCurrentlyAnimating: true) // if necessary
		}
		@objc fileprivate func MMApplication_didSendEvent(_ notification: Notification)
		{
			if self._isPresenting == false { // only if done presenting - i.e. only if this is not the same event as the spawning tap
				self._dismiss( // if necessary
					dismissEvenIfCurrentlyAnimating: false // false b/c not only are we guaranteed not to be presenting here, but this is coming from user input - we don't want to stomp on existing dismiss animations - which will race to exist here b/c of tapped!
				)
			}
		}
		@objc fileprivate func UIApplicationWillChangeStatusBarFrame()
		{
			self._dismiss(
				dismissEvenIfCurrentlyAnimating: true // just clear regardless of whether it's animating
			) // if necessary - or else it'll be off center (alternative is just move it but that's more work)
		}
		//
		// Delegation - Interface for instantiator
		func parentViewWillDisappear(animated: Bool)
		{
			self._dismiss( // if necessary
				dismissEvenIfCurrentlyAnimating: true // just clear regardless of whether it's animating
			)
			// e.g. if a user has a tooltip open during SendFunds and the 'success' transaction details view is pushed, we want the tooltip to be dismissed. is there a better way to support that than this even though this method will probably result in more code for the instantiator/integrator?
		}
	}
}
