//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class EnterNewPasswordViewController: PasswordEntryScreenBaseViewController
{
	var password_label: UICommonComponents.FormLabel!
	var password_inputView: UICommonComponents.FormInputField!
	//
	var fieldAccessoryMessageLabel: UICommonComponents.FormFieldAccessoryMessageLabel!
	//
	var confirmPassword_label: UICommonComponents.FormLabel!
	var confirmPassword_inputView: UICommonComponents.FormInputField!
	//
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: nil
			)
			view.isSecureTextEntry = true
			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
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
			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
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
	override func setup_navigation()
	{
		super.setup_navigation()
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
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		let password = self.password_inputView.text
		let confirmPassword = self.confirmPassword_inputView.text
		if password == nil || password == "" {
			return false
		} else if confirmPassword == nil || confirmPassword == "" {
			return false
		}
		return true
	}
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		if inputView != self.password_inputView {
			assert(false, "Unexpected")
			return nil
		}
		return self.confirmPassword_inputView
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
	override func _tryToSubmitForm()
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
	override func disableForm()
	{
		super.disableForm()
		//
		self.password_inputView.isEnabled = false
		self.confirmPassword_inputView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
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
		let textField_w = self.new__textField_w
		do {
			self.password_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: topPadding,
				width: textField_w,
				height: self.password_label.frame.size.height
			).integral
			self.password_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.password_label.frame.origin.y + self.password_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.password_inputView.frame.size.height
			).integral
		}
		do {
			self.fieldAccessoryMessageLabel.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.password_inputView.frame.origin.y + self.password_inputView.frame.size.height + 7,
				width: textField_w,
				height: 0
			).integral
			self.fieldAccessoryMessageLabel.sizeToFit()
		}
		do {
			self.confirmPassword_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.fieldAccessoryMessageLabel.frame.origin.y + self.fieldAccessoryMessageLabel.frame.size.height + 30,
				width: textField_w,
				height: self.confirmPassword_label.frame.size.height
			).integral
			self.confirmPassword_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.confirmPassword_label.frame.origin.y + self.confirmPassword_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.confirmPassword_inputView.frame.size.height
			).integral
		}
		self.scrollableContentSizeDidChange(withBottomView: self.confirmPassword_inputView, bottomPadding: topPadding)
	}
}
