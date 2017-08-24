//
//  PasswordEntryNavigationViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
import UIKit
//
protocol PasswordEntryModalPresentationDelegate
{
	func passwordEntryModal_willDismiss(modalViewController: PasswordEntryNavigationViewController)
	//
	func passwordEntryModal_formSubmittedWithState(
		didCancel: Bool,
		or_password password_orNil: PasswordController.Password?,
		and_passwordType passwordType_orNil: PasswordController.PasswordType?
	)
	
}
class PasswordEntryNavigationViewController: UINavigationController
{
	//
	// Constants
	enum NotificationNames: String
	{
		case willPresentInView = "PasswordEntryNavigationViewController_NotificationNames_willPresentInView"
		case willDismissView = "PasswordEntryNavigationViewController_NotificationNames_willDismissView"
		case didDismissView = "PasswordEntryNavigationViewController_NotificationNames_didDismissView"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(rawValue: self.rawValue)
		}
	}
	//
	// Properties
	var passwordEntryModalPresentationDelegate: PasswordEntryModalPresentationDelegate
	//
	// Lifecycle - Init
	init(passwordEntryModalPresentationDelegate: PasswordEntryModalPresentationDelegate)
	{
		self.passwordEntryModalPresentationDelegate = passwordEntryModalPresentationDelegate
		super.init(nibName: nil, bundle: nil)
		self.setup()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.view.backgroundColor = .contentBackgroundColor // so we don't get content flashing through transparency during modal transitions
		self.startObserving()
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(RootViewController_didAppearForFirstTime),
			name: RootViewController.NotificationNames.didAppearForFirstTime.notificationName,
			object: nil
		)
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		NotificationCenter.default.removeObserver(
			self,
			name: RootViewController.NotificationNames.didAppearForFirstTime.notificationName,
			object: nil
		)
	}
	//
	// Accessors
	var isPresented: Bool {
//		return self.view.window != nil // faulty
		return self.presentingViewController != nil
	}
	var topPasswordEntryScreenViewController: PasswordEntryScreenBaseViewController {
		// since self is the navigationController…
		return self.topViewController! as! PasswordEntryScreenBaseViewController
	}
	//
	// Imperatives
	func _configure(
		withMode taskMode: PasswordEntryPresentationController.PasswordEntryTaskMode,
		shouldAnimateToNewState: Bool
	)
	{
		let isForChangingPassword =
			taskMode == .forChangingPassword_ExistingPasswordGivenType
		 || taskMode == .forChangingPassword_NewPasswordAndType
		// we do not need to call self._clearValidationMessage() here because the ConfigureToBeShown() fns have the same effect
		do { // transition to screen
			switch taskMode
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
	var _appLaunchOnly_isWaitingForWindowControllerSetupAfterPresentCall: Bool?
	var __appLaunchIsWaitingOnly_presentArg_animated: Bool?
	@objc func present(animated: Bool)
	{
		if Thread.isMainThread == false {
			self.perform(
				#selector(present(animated:)),
				on: Thread.main,
				with: animated,
				waitUntilDone: false // should not need to block a bg thread waiting for this
			)
			return
		}
		if self.isPresented {
			if self.isBeingDismissed {
				DDLog.Warn("Passwords", "Asked to present PasswordEntry modal while still presented and being dismissed. Defer until finished.")
				// Deferring this .present(animated:) until we're doing being dismissed.
				// TODO: there may be a better (more rigorous) way to do this. isBeingDismissed appears not to get set back to false in extenuating circumstances - the mitigation of which being the reason this class was factored with/into PasswordEntryPresentationController
				self.perform(
					#selector(present(animated:)),
					on: Thread.main,
					with: animated,
					waitUntilDone: false // can't wait until done b/c (i think) we'll prevent isBeingDismissed from ever getting set back to false -- we do want to present as soon as possible - we don't want to miss the system screenshotting the app with self presented if the user is backgrounding the app
				)
				return
			}
			DDLog.Warn("Passwords", "Asked to present PasswordEntry modal while already presented and not being dismissed. Ignoring.")
			return
		}
		guard let presentModalsInViewController = WindowController.presentModalsInViewController else { // being asked to present before app has finished launching
			self._appLaunchOnly_isWaitingForWindowControllerSetupAfterPresentCall = true
			// We'll wait for notification of app launch and present self instead of doing a dispatch .async call to .present(). Otherwise there will be a delay responsible for a flash of the wallets empty screen before pw entry view presented right on app launch 
			self.__appLaunchIsWaitingOnly_presentArg_animated = animated
			// now wait for (promised) notification…
			return // and exit
		}
		do { // 'will'
			NotificationCenter.default.post(
				name: NotificationNames.willPresentInView.notificationName,
				object: nil
			)
		}
		var presentIn_viewController: UIViewController
		do {
			if let already_presentedViewController = presentModalsInViewController.presentedViewController { // must be able to display on top of existing modals
				if already_presentedViewController.isBeingDismissed == false { // e.g. the About modal when backgrounding the app
					presentIn_viewController = already_presentedViewController
				} else {
					presentIn_viewController = presentModalsInViewController
				}
			} else {
				presentIn_viewController = presentModalsInViewController
			}
		}
		self.modalPresentationStyle = .fullScreen // occlude everything
		presentIn_viewController.present(self, animated: animated, completion: nil)
	}
	func dismiss(animated: Bool = true) // this method might need to be renamed (more specifically) in the future to avoid conflict with UIKit
	{
		if self.isPresented != true {
			assert(false, "Asked to dismiss but not presented")
			return
		}
		NotificationCenter.default.post(name: NotificationNames.willDismissView.notificationName, object: nil)
		self.passwordEntryModalPresentationDelegate.passwordEntryModal_willDismiss(modalViewController: self)
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
		and_passwordType passwordType_orNil: PasswordController.PasswordType?
	)
	{
		// NOTE: we can't clear the callbacks here yet even though this is where we use them because
		// if there's a validation error, and the user wants to try again, there would be no callback through which
		// to submit the subsequent try… but we will do so in dismiss()
		//
		self.passwordEntryModalPresentationDelegate.passwordEntryModal_formSubmittedWithState(
			didCancel: didCancel,
			or_password: password_orNil,
			and_passwordType: passwordType_orNil
		)
	}
	//
	// Delegation - Validation error interface
	func validationErrorNotificationReceived(_ notification: Notification)
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
	//
	// Delegation - Notifications
	@objc func RootViewController_didAppearForFirstTime()
	{ // ^-- now, we're waiting for the rootViewController's first appearance, instead of merely the window having been made key and visible, in order to avoid the "Unbalanced calls to begin/end appearance transitions for RootViewController" issue"
		//
		if self._appLaunchOnly_isWaitingForWindowControllerSetupAfterPresentCall == true {
			let animated = self.__appLaunchIsWaitingOnly_presentArg_animated!
			//
			self._appLaunchOnly_isWaitingForWindowControllerSetupAfterPresentCall = nil
			self.__appLaunchIsWaitingOnly_presentArg_animated = nil
			//
			self.present(animated: animated)
		}
	}
}
