//
//  Tooltips.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/7/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import AMPopTip

extension UICommonComponents
{
	class TooltipSpawningLinkButtonView: UICommonComponents.LinkButtonView
	{
		//
		// Constants
		static let usabilityExpanded_w: CGFloat = 28
		static let usabilityExpanded_h: CGFloat = 32
		static let tooltip_maxWidth: CGFloat = 230 - 12 // seems to be asking for the text width instead,  -k
		//		let maxWidth: CGFloat = 230
		//		appearance.maxWidth = maxWidth
		//
		// Properties
		var tooltipText: String
		var tip: PopTip?
		//
		var tooltipDirectionFromOrigin: PopTipDirection = .up // settable by instantiator
		var willPresentTipView_fn: ((Void) -> Void)?
		//
		// Lifecycle - Init
		init(tooltipText: String) {
			self.tooltipText = tooltipText
			super.init(
				mode: .mono_default,
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
		}
		//
		// Lifecycle - Deinit
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
			self._dismiss() // just in case
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
				tip.font = .smallRegularSansSerif
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
			let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!
			var inViewController: UIViewController = rootViewController
			while inViewController.presentedViewController != nil { // 'while' necessary rather than 'if'?
				inViewController = inViewController.presentedViewController!
			}
			let inView = inViewController.view!
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
				if popTip == self.tip {
					self.tip = nil // if tip is still around, may as well release it
				} else {
					DDLog.Warn("UICommonComponents.Tooltips", "dismissHandler called but self.tip different from callback popTip")
				}
			}
		}
		func _dismiss()
		{
			if self.tip == nil {
				return
			}
			self.tip!.hide()
		}
		//
		// Delegation - Interactions
		func tapped()
		{
			if self.tip != nil {
				self._dismiss()
				return
			}
			self._present()
		}
		//
		// Delegation - Notifications
		func willDeconstructBootedStateAndClearPassword()
		{
			self._dismiss() // if necessary
		}
		//
		@objc fileprivate func MMApplication_didSendEvent(_ notification: Notification)
		{
			if self._isPresenting == false { // only if done presenting - i.e. only if this is not the same event as the spawning tap
				self._dismiss() // if necessary
			}
		}
		//
		// Delegation - Interface for instantiator
		func parentViewWillDisappear(animated: Bool)
		{
			self._dismiss() // if necessary
			// e.g. if a user has a tooltip open during SendFunds and the 'success' transaction details view is pushed, we want the tooltip to be dismissed. is there a better way to support that than this even though this method will probably result in more code for the instantiator/integrator?
		}
	}
}
