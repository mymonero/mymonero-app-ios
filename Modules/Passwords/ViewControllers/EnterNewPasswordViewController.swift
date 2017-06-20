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
	var password_label: UICommonComponents.FormLabel!
	var password_inputView: UICommonComponents.FormInputField!
	//
	var fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
	//
	var confirmPassword_label: UICommonComponents.FormLabel!
	var confirmPassword_inputView: UICommonComponents.FormInputField!
	//
	override func setup()
	{
		super.setup()
		self.setup_subviews() // before nav, cause nav setup references subviews
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
	func setup_subviews()
	{
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: nil
			)
			view.isSecureTextEntry = true
			view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
			view.delegate = self
			view.returnKeyType = .next
			self.password_inputView = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("PIN OR PASSWORD", comment: ""),
				sizeToFit: true
			)
			self.password_label = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: NSLocalizedString("This app-wide password (or PIN) will be used to encrypt your data on your device, and to lock your app when you are idle. Don't forget it!\nSix character minimum.", comment: "")
			)
			self.fieldAccessoryMessageLabel = view
			self.view.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: ""
			)
			view.isSecureTextEntry = true
			view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
			view.delegate = self
			view.returnKeyType = .go
			self.confirmPassword_inputView = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("CONFIRM", comment: ""),
				sizeToFit: true
			)
			self.confirmPassword_label = view
			self.view.addSubview(view)
		}
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
		let password = self.password_inputView.text!
		let confirmationPassword = self.confirmPassword_inputView.text!
		if password != confirmationPassword {
			self.setValidationMessage("Oops, that doesn't match")
			return
		}
		if confirmationPassword.characters.count < 6 {
			self.setValidationMessage("Please enter more than 6 characters")
			return
		}
		self.clearValidationMessage()
		self.disableForm() // for slow platforms (is this necessary in this, the native app?)
		self._yield_nonZeroPasswordAndPasswordType()
	}
	func _yield_nonZeroPasswordAndPasswordType()
	{
		self.userSubmittedNonZeroPassword_cb!(self.password_inputView.text!)
	}
	func disableForm()
	{
		self.navigationItem.rightBarButtonItem!.isEnabled = false
		//
		self.password_inputView.isEnabled = false
		self.confirmPassword_inputView.isEnabled = false
	}
	override func reEnableForm()
	{
		self.navigationItem.rightBarButtonItem!.isEnabled = true
		//
		self.password_inputView.isEnabled = true
		self.password_inputView.becomeFirstResponder() // since disable would have de-focused
		self.confirmPassword_inputView.isEnabled = true
	}
	//
	// Overrides - Imperatives - Validation
	override func setValidationMessage(_ message: String)
	{
		self.confirmPassword_inputView.setValidationError(message)
	}
	override func clearValidationMessage()
	{
		self.confirmPassword_inputView.clearValidationError()
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
	// Delegation - View
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		//
		self.password_inputView.becomeFirstResponder()
	}
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let topPadding: CGFloat = 20
		let textField_x: CGFloat = CGFloat.form_input_margin_x
		let labels_x: CGFloat  = CGFloat.form_label_margin_x
		let textField_w: CGFloat = self.view.frame.size.width - 2 * textField_x
		do {
			self.password_label.frame = CGRect(
				x: labels_x,
				y: topPadding,
				width: textField_w,
				height: self.password_label.frame.size.height
			).integral
			self.password_inputView.frame = CGRect(
				x: textField_x,
				y: self.password_label.frame.origin.y + self.password_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.password_inputView.frame.size.height
			).integral
		}
		do {
			self.fieldAccessoryMessageLabel.frame = CGRect(
				x: labels_x,
				y: self.password_inputView.frame.origin.y + self.password_inputView.frame.size.height + 7,
				width: textField_w,
				height: 0
			).integral
			self.fieldAccessoryMessageLabel.sizeToFit()
		}
		do {
			self.confirmPassword_label.frame = CGRect(
				x: labels_x,
				y: self.fieldAccessoryMessageLabel.frame.origin.y + self.fieldAccessoryMessageLabel.frame.size.height + 30,
				width: textField_w,
				height: self.confirmPassword_label.frame.size.height
			).integral
			self.confirmPassword_inputView.frame = CGRect(
				x: textField_x,
				y: self.confirmPassword_label.frame.origin.y + self.confirmPassword_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.confirmPassword_inputView.frame.size.height
			).integral
		}
//		let bottomPadding = topPadding
//		self.contentSize = CGSize(
//			width: self.frame.size.width,
//			height: self.confirmPassword_inputView.frame.origin.y + self.confirmPassword_inputView.frame.size.height + bottomPadding
//		)
	}
	//
	// Delegation - Password field - Control events
	@objc func aPasswordField_editingChanged()
	{
		let password = self.password_inputView.text
		let confirmPassword = self.confirmPassword_inputView.text
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
	//
	// Delegation - UITextField
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if self.password_inputView.isFirstResponder {
			self.confirmPassword_inputView.becomeFirstResponder()
			return false
		}
		self.aPasswordField_didReturn()
		return false
	}
	//
	// Delegation - Password field - Internal events
	func aPasswordField_didReturn()
	{
		if self.navigationItem.rightBarButtonItem!.isEnabled {
			self._tryToSubmitForm()
		}
	}
}
