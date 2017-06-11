//
//  PasswordEntryBaseView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
protocol PasswordEntryTextFieldEventDelegate
{
	func aPasswordField_editingChanged()
	func aPasswordField_didReturn()
}
//
class PasswordEntryScreenBaseViewController: UIViewController, UITextFieldDelegate
{
	var isForChangingPassword: Bool!
	//
	// Consumers: set these after init
	var userSubmittedNonZeroPassword_cb: ((_ password: PasswordController.Password) -> Void)!
	var cancelButtonPressed_cb: ((Void) -> Void)!
	//
	init(isForChangingPassword: Bool)
	{
		super.init(nibName: nil, bundle: nil)
		//
		self.isForChangingPassword = isForChangingPassword
		self.setup()
	}
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	func setup()
	{
		self.view.backgroundColor = UIColor.contentBackgroundColor
	}
	//
	// Imperatives - Validation error
	func setValidationMessage(_ message: String)
	{
		assert(false, "override \(#function)")
	}
	func clearValidationMessage()
	{
		assert(false, "override \(#function)")
	}
	//
	// Imperatives - Exposed for PasswordEntryNavigationViewController
	func reEnableForm()
	{
		assert(false, "override \(#function)")
	}
}
