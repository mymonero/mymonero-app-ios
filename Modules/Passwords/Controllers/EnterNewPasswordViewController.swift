//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class EnterNewPasswordViewController: PasswordEntryScreenBaseViewController, PasswordEntryTextFieldEventDelegate
{
	override func setup()
	{
		super.setup()
		self.setup_navigation()
	}
	func setup_navigation()
	{
		var navigationTitle: String!
		if self.isForChangingPassword == true {
			navigationTitle = "Create New PIN or Password"
		} else {
			navigationTitle = "Create PIN or Password"
		}
		self.navigationItem.title = navigationTitle
		self.navigationItem.leftBarButtonItem = self._new_leftBarButtonItem()
		self.navigationItem.rightBarButtonItem = self._new_rightBarButtonItem()
	}
	//
	// Setup - Imperatives - Overrides
	override func loadView()
	{
		self.view = EnterNewPasswordView()
		self.passwordView.textFieldEventDelegate = self
	}
	//
	// Accessors - Lookups - Views
	var passwordView: EnterNewPasswordView!
	{
		return self.view as! EnterNewPasswordView
	}
	//
	// Accessors - Factories - Views
	func _new_leftBarButtonItem() -> UICommonComponents.NavigationBarButtonItem?
	{
		let item = UICommonComponents.NavigationBarButtonItem(
			type: .cancel,
			target: self,
			action: #selector(tapped_leftBarButtonItem)
		)
		return item
	}
	func _new_rightBarButtonItem() -> UICommonComponents.NavigationBarButtonItem?
	{
		let item = UICommonComponents.NavigationBarButtonItem(
			type: .save,
			target: self,
			action: #selector(tapped_rightBarButtonItem),
			title_orNilForDefault: NSLocalizedString("Next", comment: "")
		)
		item.isEnabled = false // need to enter PW first
		//
		return item
	}
	//
	// Imperatives
	func _tryToSubmitForm()
	{
		let password = self.passwordView.password_inputView.text!
		let confirmationPassword = self.passwordView.confirmPassword_inputView.text!
		if password != confirmationPassword {
			self.setValidationMessage("Oops, that doesn't match")
			return
		}
		if confirmationPassword.characters.count < 6 {
			self.setValidationMessage("Please enter more than 6 characters")
			return
		}
		self.clearValidationMessage()
		self.__disableForm() // for slow platforms (is this necessary in this, the native app?)
		self._yield_nonZeroPasswordAndPasswordType()
	}
	func _yield_nonZeroPasswordAndPasswordType()
	{
		self.userSubmittedNonZeroPassword_cb!(self.passwordView.password_inputView.text!)
	}
	func __disableForm()
	{
		self.navigationItem.rightBarButtonItem!.isEnabled = false
		self.passwordView.disable()
	}
	func __reEnableForm()
	{
		self.navigationItem.rightBarButtonItem!.isEnabled = true
		self.passwordView.reEnable()
	}
	//
	// Delegation - Navigation bar buttons
	@objc
	func tapped_leftBarButtonItem()
	{
		if let cb = self.cancelButtonPressed_cb {
			cb()
		}
	}
	@objc
	func tapped_rightBarButtonItem()
	{
		self._tryToSubmitForm()
	}
	//
	// Delegation - View lifecycle
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		//
		self.passwordView.password_inputView.becomeFirstResponder()
	}
	//
	// Delegation/Protocols - PasswordEntryTextFieldEventDelegate
	func aPasswordField_editingChanged()
	{
		let password = self.passwordView.password_inputView.text
		let confirmPassword = self.passwordView.confirmPassword_inputView.text
		var submitEnabled: Bool;
		if password == nil || password == "" {
			submitEnabled = false
		} else if confirmPassword == nil || confirmPassword == "" {
			submitEnabled = false
		} else {
			submitEnabled = true
		}
		self.navigationItem.rightBarButtonItem!.isEnabled = submitEnabled
	}
	func aPasswordField_didReturn()
	{
		if self.navigationItem.rightBarButtonItem!.isEnabled {
			self._tryToSubmitForm()
		}
	}
}
