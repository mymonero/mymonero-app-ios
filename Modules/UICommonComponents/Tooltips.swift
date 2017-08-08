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
		static let w: CGFloat = 30
		static let fixed_h: CGFloat = 30
		static let tooltip_maxWidth: CGFloat = 230
		//		let maxWidth: CGFloat = 230
		//		appearance.maxWidth = maxWidth
		//
		// Properties
		var tooltipText: String
		var tip: PopTip?
		//
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
			// TODO: poptip & app events observation
			self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
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
				//
				tip.shouldDismissOnTap = false // we'll observe other events - do not want conflict
			}
			self.tip = tip
			let inView = UIApplication.shared.delegate!.window!!.rootViewController!.view!
			tip.show(
				text: self.tooltipText,
				direction: .up,
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
		// Delegation - Notifications
		@objc
		fileprivate func MMApplication_didSendEvent(_ notification: Notification)
		{
			if self._isPresenting == false { // done presenting - i.e. not same event as spawning tap
				self._dismiss() // if necessary (will this race with tap on self?)
			}
		}
	}
}
