//
//  PasswordEntryPresentationController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/5/17.
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
import UIKit

class PasswordEntryPresentationController: PasswordEntryDelegate, PasswordEntryModalPresentationDelegate
{
	//
	// Constants
	enum PasswordEntryTaskMode
	{
		case forUnlockingApp_ExistingPasswordGivenType
		case forFirstEntry_NewPasswordAndType
		//
		case forChangingPassword_ExistingPasswordGivenType
		case forChangingPassword_NewPasswordAndType
		//
		case forAuthorizingAppAction
	}
	//
	// Static
	static let shared = PasswordEntryPresentationController() // must be instantiate early on before anyone has a chance to ask for the password
	//
	// Properties
	var passwordController_notificationTokens: [Any]?
	var taskMode: PasswordEntryTaskMode?
	var passwordEntryNavigationViewController: PasswordEntryNavigationViewController?
	//
	// Lifecycle - Init
	init()
	{
		self.setup()
	}
	func setup()
	{
		self.startObserving_passwordController()
	}
	func startObserving_passwordController()
	{
		PasswordController.shared.setPasswordEntryDelegate(to: self)
		//
		self.passwordController_notificationTokens = []
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.obtainedNewPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.dismiss(animated: true)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.obtainedCorrectExistingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.dismiss(animated: true)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.erroredWhileSettingNewPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.erroredWhileGettingExistingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.errorWhileChangingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.errorWhileAuthorizingForAppAction.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.successfullyAuthenticatedForAppAction.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.passwordEntryNavigationViewController!.dismiss(animated: true)
			}
		))
		//
		// For delete everything, idle, lock-down, etc
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				if self.passwordEntryNavigationViewController != nil { // then it's 'presented' and should be canceled
					if self.passwordEntryNavigationViewController == nil {
						DDLog.Warn("Passwords", "Notification that .willDeconstructBootedStateAndClearPassword was received while view controller was not presented. Ignoring.")
						return
					}
					if self.passwordEntryNavigationViewController!.presentingViewController == nil {
						assert(false, "Unexpected: Notification that .willDeconstructBootedStateAndClearPassword was received while not presented.")
						return
					}
					if self.passwordEntryNavigationViewController!.isBeingDismissed { // expecting this to be nil by now
						assert(false, "Unexpected: Notification that .willDeconstructBootedStateAndClearPassword was received while presented but being dismissed.")
						return // we do not need to cancel this b/c it's already being dismissed; user probably backgrounded app just after closing self
					}
//					let userInfo = notification.userInfo!
//					let isForADeleteEverything = userInfo[PasswordController.Notification_UserInfo_Keys.isForADeleteEverything.rawValue] as! Bool
					let isAnimated = false // make it not possible for re-enable of Wallet tab bar item appears to race with selecting it
					self.passwordEntryNavigationViewController!.cancel(animated: isAnimated)
					// ^-- we must:
					//	 (a) use cancel() to maintain pw controller state (or user idle while changing pw breaks ask-for-pw), and
					//	 (b) have no animation unless it's for a 'delete everything'
					// i.e. we will teardown whole password controller and then wait for imminent non-animated re-present of new self (which does not happen in the case of a 'delete everything')

					
				}
			}
		))
// 'did' not necessary:
//		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
//			forName: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
//			object: PasswordController.shared,
//			queue: OperationQueue.main,
//			using:
//			{ [unowned self] (notification) in
//			}
//		)
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.stopObserving_passwordController()
	}
	func stopObserving_passwordController()
	{
		PasswordController.shared.clearPasswordEntryDelegate(from: self)
		//
		guard let passwordController_notificationTokens = self.passwordController_notificationTokens else {
			assert(false, "nil self.passwordController_notificationTokens")
			return
		}
		for (_, token) in passwordController_notificationTokens.enumerated() {
			NotificationCenter.default.removeObserver(token)
		}
		self.passwordController_notificationTokens = nil // not strictly necessary for a deinit call
	}
	//
	// Protocol - PasswordEntryDelegate
	var uuidString = UUID().uuidString
	func identifier() -> String
	{
		return self.uuidString
	}
	var enterExistingPassword_cb: ((Bool?, PasswordController.Password?) -> Void)?
	func getUserToEnterExistingPassword(
		isForChangePassword: Bool,
		isForAuthorizingAppActionOnly: Bool, // normally no - for things like SendFunds
		customNavigationBarTitle: String?, // normally nil
		_ enterExistingPassword_cb: @escaping (Bool?, PasswordController.Password?) -> Void
	) {
		assert(isForChangePassword == false || isForAuthorizingAppActionOnly == false) // both shouldn't be true
		let shouldAnimateToNewState = isForChangePassword || isForAuthorizingAppActionOnly
		// ^--- TODO: this needs to also be true for the rare case that they have deleted all wallets and other data, have killed and relaunched the app (so they have not entered the pw but have not been asked for it yet), and are adding a wallet back
		do { // check legality
			if self.taskMode != nil {
				assert(false, "getUserToEnterExistingPassword called but self.passwordEntryTaskMode not none/nil")
				return
			}
		}
		do { // we need to hang onto the callback for when the form is submitted
			self.enterExistingPassword_cb = enterExistingPassword_cb
		}
		// lazy instantiate
		if self.passwordEntryNavigationViewController == nil {
			self.passwordEntryNavigationViewController = PasswordEntryNavigationViewController(
				passwordEntryModalPresentationDelegate: self
			)
		}
		do { // put view into mode
			var taskMode: PasswordEntryTaskMode
			if isForChangePassword {
				taskMode = .forChangingPassword_ExistingPasswordGivenType
			} else if isForAuthorizingAppActionOnly {
				taskMode = .forAuthorizingAppAction
			} else  {
				taskMode = .forUnlockingApp_ExistingPasswordGivenType
			}
			self.taskMode = taskMode
			//
			self.passwordEntryNavigationViewController!._configure(
				withMode: taskMode,
				shouldAnimateToNewState: shouldAnimateToNewState,
				customNavigationBarTitle: customNavigationBarTitle
			)
		}
		self.passwordEntryNavigationViewController!.present(animated: shouldAnimateToNewState)
	}
	var enterNewPasswordAndType_cb: ((Bool?, PasswordController.Password?, PasswordController.PasswordType?) -> Void)?
	func getUserToEnterNewPasswordAndType(
		isForChangePassword: Bool,
		_ enterNewPasswordAndType_cb: @escaping (Bool?, PasswordController.Password?, PasswordController.PasswordType?) -> Void
	) {
		let shouldAnimateToNewState = isForChangePassword
		do { // check legality
			if self.taskMode != nil {
				if self.taskMode != .forChangingPassword_ExistingPasswordGivenType {
					assert(false, "getUserToEnterNewPasswordAndType called but passwordEntry taskMode not none/nil and not .forChangingPassword_ExistingPasswordGivenType")
					return
				}
			}
		}
		do { // we need to hang onto the callback for when the form is submitted
			self.enterNewPasswordAndType_cb = enterNewPasswordAndType_cb
		}
		// lazy instantiate
		if self.passwordEntryNavigationViewController == nil {
			self.passwordEntryNavigationViewController = PasswordEntryNavigationViewController(
				passwordEntryModalPresentationDelegate: self
			)
		}
		do { // put view into mode
			var taskMode: PasswordEntryTaskMode!
			if isForChangePassword == true {
				taskMode = .forChangingPassword_NewPasswordAndType
			} else {
				taskMode = .forFirstEntry_NewPasswordAndType
			}
			self.taskMode = taskMode
			//
			self.passwordEntryNavigationViewController!._configure(
				withMode: taskMode,
				shouldAnimateToNewState: shouldAnimateToNewState,
				customNavigationBarTitle: nil // not supported here
			)
		}
		self.passwordEntryNavigationViewController!.present(animated: true) // this is for NEW password, so we want this to show with an animation
		// because it's going to be requested after the user has already initiated activity
	}
	//
	// Delegation - PasswordEntryModalPresentationDelegate
	func passwordEntryModal_willDismiss(modalViewController: PasswordEntryNavigationViewController)
	{
		do { // clear state for next time
			self.taskMode = nil
		}
		do { // clear both callbacks as well since we're no longer going to call back with either of the current values
			self.enterExistingPassword_cb = nil
			self.enterNewPasswordAndType_cb = nil
		}
		self.passwordEntryNavigationViewController = nil // TODO: is this too early to free? do we need to wait til didDismiss?
	}
	func passwordEntryModal_formSubmittedWithState(
		didCancel: Bool,
		or_password password_orNil: PasswordController.Password?,
		and_passwordType passwordType_orNil: PasswordController.PasswordType?
	) {
		assert(self.taskMode != nil, "nil self.taskMode")
		switch self.taskMode! {
		case .forUnlockingApp_ExistingPasswordGivenType,
		     .forChangingPassword_ExistingPasswordGivenType,
			 .forAuthorizingAppAction:
			guard let enterExistingPassword_cb = self.enterExistingPassword_cb else {
				assert(false, "PasswordEntryView/_passwordController_callBack_trampoline: missing enterPassword_cb for passwordEntryTaskMode: \(self.taskMode!)")
				return
			}
			enterExistingPassword_cb(
				didCancel,
				password_orNil
			)
			// we don't want to free/zero the cb here - user may get pw wrong and try again
			break
			
		case .forFirstEntry_NewPasswordAndType,
		     .forChangingPassword_NewPasswordAndType:
			
			guard let enterNewPasswordAndType_cb = self.enterNewPasswordAndType_cb else {
				assert(false, "PasswordEntryView/_passwordController_callBack_trampoline: missing enterPasswordAndType_cb for passwordEntryTaskMode: \(self.taskMode!)")
				return
			}
			enterNewPasswordAndType_cb(
				didCancel,
				password_orNil,
				passwordType_orNil
			)
			// we don't want to free/zero the cb here - might trigger validation err & need to be called again
			break
			
		}
	}
}
