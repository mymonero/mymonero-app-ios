//
//  PasswordEntryNavigationViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PasswordEntryNavigationViewController: UINavigationController, PasswordEntryDelegate
{
	enum PasswordEntryTaskMode
	{
		case forUnlockingApp_ExistingPasswordGivenType
		case forFirstEntry_NewPasswordAndType
		//
		case forChangingPassword_ExistingPasswordGivenType
		case forChangingPassword_NewPasswordAndType
	}
	enum NotificationNames: String
	{
		case willPresentInView = "PasswordEntryNavigationViewController_NotificationNames_willPresentInView"
		case willDismissView = "PasswordEntryNavigationViewController_NotificationNames_willDismissView"
		case didDismissView = "PasswordEntryNavigationViewController_NotificationNames_didDismissView"
		//
		var notificationName: NSNotification.Name
		{
			return NSNotification.Name(rawValue: self.rawValue)
		}
	}
	//
	var taskMode: PasswordEntryTaskMode?
	//
	init()
	{
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.startObserving_passwordController()
	}
	var passwordController_notificationTokens: [Any]?
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
				self.dismiss(animated: true)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.obtainedCorrectExistingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				self.dismiss(animated: true)
			}
		))
		func __validationErrorNotificationReceived(_ notification: Notification)
		{
			self.topPasswordEntryScreenViewController.reEnableForm()
			//
			let userInfo = notification.userInfo!
			let err_str = userInfo[PasswordController.Notification_UserInfo_Keys.err_str.rawValue] as! String
			if err_str != "" {
				self.topPasswordEntryScreenViewController.setValidationMessage(err_str)
			} else {
				self.topPasswordEntryScreenViewController.clearValidationMessage()
			}
		}
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.erroredWhileSettingNewPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ (notification) in
				__validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.erroredWhileGettingExistingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ (notification) in
				__validationErrorNotificationReceived(notification)
			}
		))
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.errorWhileChangingPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ (notification) in
				__validationErrorNotificationReceived(notification)
			}
		))
		//
		// For delete everything and idle
		self.passwordController_notificationTokens!.append(NotificationCenter.default.addObserver(
			forName: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
			object: PasswordController.shared,
			queue: OperationQueue.main,
			using:
			{ [unowned self] (notification) in
				let userInfo = notification.userInfo!
				let isForADeleteEverything = userInfo[PasswordController.Notification_UserInfo_Keys.isForADeleteEverything.rawValue] as! Bool
				let isAnimated = isForADeleteEverything == true
				self.cancel(animated: isAnimated)
				// ^-- we must:
				//	 (a) use cancel() to maintain pw controller state (or user idle while changing pw breaks ask-for-pw), and
				//	 (b) have no animation unless it's for a 'delete everything'
				// i.e. we will teardown whole password controller and then wait for imminent non-animated re-present of new self (which does not happen in the case of a 'delete everything')
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
	deinit {
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
	// Accessors
	var isPresented: Bool
	{
		return self.view.window != nil
	}
	var topPasswordEntryScreenViewController: PasswordEntryScreenBaseViewController
	{ // since self is the navigationController…
		return self.topViewController! as! PasswordEntryScreenBaseViewController
	}
	//
	// Imperatives
	func _configureWithMode(shouldAnimateToNewState: Bool)
	{
		let isForChangingPassword =
			self.taskMode == .forChangingPassword_ExistingPasswordGivenType
		 || self.taskMode == .forChangingPassword_NewPasswordAndType
		// we do not need to call self._clearValidationMessage() here because the ConfigureToBeShown() fns have the same effect
		do { // transition to screen
			switch self.taskMode!
			{
				case .forUnlockingApp_ExistingPasswordGivenType,
				     .forChangingPassword_ExistingPasswordGivenType:
					let controller = EnterExistingPasswordViewController(isForChangingPassword: isForChangingPassword)
					controller.userSubmittedNonZeroPassword_cb =
					{ [unowned self] password in
						self.submitForm(password: password)
					}
					controller.cancelButtonPressed_cb =
					{ [unowned self] in
						self.cancel(animated: true)
					}
					self.viewControllers = [ controller ] // i don't know of any cases where `animated` should be true - and there are reasons we don't want it to be - there's no 'old_topStackView'
					break
				
				case .forFirstEntry_NewPasswordAndType,
				     .forChangingPassword_NewPasswordAndType:
					let controller = EnterNewPasswordViewController(isForChangingPassword: isForChangingPassword)
					controller.userSubmittedNonZeroPassword_cb =
					{ [unowned self] password in
						self.submitForm(password: password)
					}
					controller.cancelButtonPressed_cb =
					{ [unowned self] in
						self.cancel(animated: true)
					}
					if self.viewControllers.count == 0 {
						self.viewControllers = [ controller ]
					} else {
						self.pushViewController(controller, animated: shouldAnimateToNewState)
					}
					break
				
			}
		}
	}
	//
	// Imperatives - Presentation
	func present(animated: Bool)
	{
		DispatchQueue.main.async
		{ [unowned self] in // we should wait until next tick b/c the app (and thus window) may not be finished setting up yet
			NotificationCenter.default.post(
				name: NotificationNames.willPresentInView.notificationName,
				object: nil
			)
			//
			let parentViewController = UIApplication.shared.delegate!.window!!.rootViewController!
			DispatchQueue.main.async
			{ [unowned self] in // on next 'tick' to wait for app to finish launching, if necessary; plus good to be on main
				parentViewController.present(self, animated: animated, completion: nil)
			}
		}
	}
	func dismiss(animated: Bool = true) // this method might need to be renamed (more specifically) in the future to avoid conflict with UIKit
	{
		if self.isPresented != true {
			assert(false, "Asked to dismiss but not presented")
			return
		}
		NotificationCenter.default.post(name: NotificationNames.willDismissView.notificationName, object: nil)
		do { // clear state for next time
			self.taskMode = nil
		}
		do { // clear both callbacks as well since we're no longer going to call back with either of the current values
			self.enterExistingPassword_cb = nil
			self.enterNewPasswordAndType_cb = nil
		}
		self.dismiss(animated: animated, completion:
		{
			NotificationCenter.default.post(name: NotificationNames.didDismissView.notificationName, object: nil)
		})
	}
	//
	// Imperatives - Form actions
	func submitForm(password: PasswordController.Password)
	{
		self.topPasswordEntryScreenViewController.clearValidationMessage()
		// handles validation:
		let passwordType = PasswordController.PasswordType.new(detectedFromPassword: password)
		self._passwordController_callBack_trampoline(
			didCancel: false,
			or_password: password,
			and_passwordType: passwordType
		)
	}
	func cancel(animated: Bool)
	{
		self._passwordController_callBack_trampoline(
			didCancel: true,
			or_password: nil,
			and_passwordType: nil
		)
		//
		func _really_dismiss()
		{
			self.dismiss(animated: animated)
		}
		if animated != true {
			_really_dismiss() // we don't want any delay - because that could mess with consumers'/callers' serialization
		} else {
			DispatchQueue.main.async
			{ // do on next tick so as to avoid animation jank
				_really_dismiss()
			}
		}
	}
	func _passwordController_callBack_trampoline(
		didCancel: Bool,
		or_password password_orNil: PasswordController.Password?,
		and_passwordType passwordType_orNil: PasswordController.PasswordType?)
	{
		// NOTE: we can't clear the callbacks here yet even though this is where we use them because
		// if there's a validation error, and the user wants to try again, there would be no callback through which
		// to submit the subsequent try… but we will do so in dismiss()
		//
		assert(self.taskMode != nil, "nil self.taskMode")
		switch self.taskMode! {
			case .forUnlockingApp_ExistingPasswordGivenType,
			     .forChangingPassword_ExistingPasswordGivenType:
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
		_ enterExistingPassword_cb: @escaping (Bool?, PasswordController.Password?) -> Void
	)
	{
		let shouldAnimateToNewState = isForChangePassword == true
		do { // check legality
			if self.taskMode != nil {
				assert(false, "getUserToEnterExistingPassword called but self.passwordEntryTaskMode not none/nil")
				return
			}
		}
		do { // we need to hang onto the callback for when the form is submitted
			self.enterExistingPassword_cb = enterExistingPassword_cb
		}
		do { // put view into mode
			var taskMode: PasswordEntryTaskMode
			if isForChangePassword {
				taskMode = .forChangingPassword_ExistingPasswordGivenType
			} else {
				taskMode = .forUnlockingApp_ExistingPasswordGivenType
			}
			self.taskMode = taskMode
			//
			self._configureWithMode(shouldAnimateToNewState: shouldAnimateToNewState)
		}
		self.present(animated: shouldAnimateToNewState)
	}
	var enterNewPasswordAndType_cb: ((Bool?, PasswordController.Password?, PasswordController.PasswordType?) -> Void)?
	func getUserToEnterNewPasswordAndType(
		isForChangePassword: Bool,
		_ enterNewPasswordAndType_cb: @escaping (Bool?, PasswordController.Password?, PasswordController.PasswordType?) -> Void
		)
	{
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
		do { // put view into mode
			var taskMode: PasswordEntryTaskMode!
			if isForChangePassword == true {
				taskMode = .forChangingPassword_NewPasswordAndType
			} else {
				taskMode = .forFirstEntry_NewPasswordAndType
			}
			self.taskMode = taskMode
			//
			self._configureWithMode(shouldAnimateToNewState: shouldAnimateToNewState)
		}
		self.present(animated: true) // this is for NEW password, so we want this to show with an animation
		// because it's going to be requested after the user has already initiated activity
	}
}
