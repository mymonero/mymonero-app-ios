//
//  PasswordEntryViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class PasswordEntryViewController: UINavigationController, PasswordEntryDelegate
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
		case willPresentInView = "PasswordEntryViewController_NotificationNames_willPresentInView"
		case willDismissView = "PasswordEntryViewController_NotificationNames_willDismissView"
		case didDismissView = "PasswordEntryViewController_NotificationNames_didDismissView"
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
		PasswordController.shared.passwordEntryDelegate = self // self-elect as singular delegate - TODO: maybe use a setter fn which checks if a delegate already exists
	}
	//
	// Accessors
	var isPresented: Bool
	{
		return self.view.window != nil
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
						// TODO:
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
		NotificationCenter.default.post(
			name: NotificationNames.willPresentInView.notificationName,
			object: nil
		)
		//
		let parentViewController = UIApplication.shared.delegate!.window!!.rootViewController!
		DispatchQueue.main.async
		{ // on next 'tick' to wait for app to finish launching, if necessary; plus good to be on main
			parentViewController.present(self, animated: animated, completion: nil)
		}
	}
	func dismiss(animated: Bool)
	{
		assert(false, "TODO")
	}
	//
	// Imperatives - Form actions
	func submitForm(password: PasswordController.Password)
	{
//			{
//				self._clearValidationMessage()
//		}
//		// handles validation:
//		const passwordType = self.passwordTypeChosenWithPasswordIfNewPassword_orUndefined(password)
//		self._passwordController_callBack_trampoline(
//			false, // didCancel?
//			password,
//			passwordType
//		)
	}
	func cancel(animated: Bool? = false)
	{
//		const isAnimated = optl_isAnimated === false ? false : true
//		//
//		const self = this
//		self._passwordController_callBack_trampoline(
//			true, // didCancel
//			undefined,
//			undefined
//		)
//		//
//		function _really_dismiss()
//			{
//				self.dismiss(animated: animated)
//		}
//		if (isAnimated !== true) {
//			_really_Dismiss() // we don't want any delay - because that could mess with consumers'/callers' serialization
//		} else {
//			setTimeout(_really_Dismiss) // do on next tick so as to avoid animation jank
//		}
	}
	func _passwordController_callBack_trampoline(
		didCancel: Bool,
		password_orNil: PasswordController.Password,
		passwordType_orNil: PasswordController.PasswordType)
	{
//		const self = this
//		//
//		// NOTE: we unfortunately can't just clear the callbacks here even though this is where we use them because
//		// if there's a validation error, and the user wants to try again, there would be no callback through which
//		// to submit the subsequent try
//		//
//		switch (self.passwordEntryTaskMode) {
//		case passwordEntryTaskModes.ForUnlockingApp_ExistingPasswordGivenType:
//		case passwordEntryTaskModes.ForChangingPassword_ExistingPasswordGivenType:
//		{
//			{ // validate cb state
//				if (typeof self.enterPassword_cb === 'undefined' || self.enterPassword_cb === null) {
//					throw "PasswordEntryView/_passwordController_callBack_trampoline: missing enterPassword_cb for passwordEntryTaskMode: " + self.passwordEntryTaskMode
//				}
//			}
//			self.enterPassword_cb(
//				didCancel,
//				password_orNil
//			)
//			// we don't want to free/zero the cb here - user may get pw wrong and try again
//			break
//			}
//		case passwordEntryTaskModes.ForFirstEntry_NewPasswordAndType:
//		case passwordEntryTaskModes.ForChangingPassword_NewPasswordAndType:
//		{
//			{ // validate cb state
//				if (typeof self.enterPasswordAndType_cb === 'undefined' || self.enterPasswordAndType_cb === null) {
//					throw "PasswordEntryView/_passwordController_callBack_trampoline: missing enterPasswordAndType_cb for passwordEntryTaskMode: " + self.passwordEntryTaskMode
//				}
//			}
//			self.enterPasswordAndType_cb(
//				didCancel,
//				password_orNil,
//				passwordType_orNil
//			)
//			// we don't want to free/zero the cb here - might trigger validation err & need to be called again
//			break
//			}
//		case passwordEntryTaskModes.None:
//			throw "_passwordController_callBack_trampoline called when self.passwordEntryTaskMode .None"
//		//
//		default:
//			throw "This switch ought to have been exhaustive"
//		}
	}

	//
	// Protocol - PasswordEntryDelegate
	var enterExistingPassword_cb: ((Bool?, PasswordController.Password?) -> Void)?
	func getUserToEnterExistingPassword(
		isForChangePassword: Bool,
		_ enterExistingPassword_cb: @escaping (Bool?, PasswordController.Password?) -> Void
	)
	{
		// TODO: if not view, create view
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
