//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class EnterExistingPasswordViewController: PasswordEntryScreenBaseViewController, PasswordEntryTextFieldEventDelegate
{
	override func setup()
	{
		super.setup()
		self.edgesForExtendedLayout = [ .top ] // do slide under nav bar, in this case
		self.extendedLayoutIncludesOpaqueBars = true // since we use an opaque bar
		self.setup_navigation()
	}
	func setup_navigation()
	{
		self.navigationItem.title = "Enter \(PasswordController.shared.passwordType.capitalized_humanReadableString)"
		self.navigationItem.leftBarButtonItem = self._new_leftBarButtonItem()
		self.navigationItem.rightBarButtonItem = self._new_rightBarButtonItem()
	}
	//
	// Setup - Imperatives - Overrides
	override func loadView()
	{
		self.view = EnterExistingPasswordView()
		self.passwordView.textFieldEventDelegate = self
	}
	//
	// Accessors - Lookups - Views
	var passwordView: EnterExistingPasswordView!
	{
		return self.view as! EnterExistingPasswordView
	}
	//
	// Accessors - Factories - Views
	func _new_leftBarButtonItem() -> UICommonComponents.NavigationBarButtonItem?
	{
		if self.isForChangingPassword != true {
			return nil
		}
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
		let passwordInputValue = self.passwordView.password_inputView.text
		item.isEnabled = passwordInputValue != nil && passwordInputValue != "" // need to enter PW first
		//
		return item
	}
	//
	// Imperatives
	func _tryToSubmitForm()
	{
		self.__disableForm()
		// we can assume pw is not "" here
		self.__yield_nonZeroPassword()
	}
	func __yield_nonZeroPassword()
	{
		if let cb = userSubmittedNonZeroPassword_cb {
			cb(self.passwordView.password_inputView.text!)
		}
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
		let submitEnabled = password != nil && password != ""
		self.navigationItem.rightBarButtonItem!.isEnabled = submitEnabled
	}
	func aPasswordField_didReturn()
	{
		if self.navigationItem.rightBarButtonItem!.isEnabled != false {
			self._tryToSubmitForm()
		}
	}
}
