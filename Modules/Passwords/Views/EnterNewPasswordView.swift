//
//  EnterExistingPasswordView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
class EnterNewPasswordView: PasswordEntryScreenBaseView
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
		//
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: nil
			)
			view.isSecureTextEntry = true
			view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
			view.delegate = self
			view.returnKeyType = .next
			self.password_inputView = view
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("PIN OR PASSWORD", comment: ""),
				sizeToFit: true
			)
			self.password_label = view
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormFieldAccessoryMessageLabel(
				text: NSLocalizedString("This app-wide password (or PIN) will be used to encrypt your data on your device, and to lock your app when you are idle. Don't forget it!\nSix character minimum.", comment: "")
			)
			self.fieldAccessoryMessageLabel = view
			self.addSubview(view)
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
			self.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormLabel(
				title: NSLocalizedString("CONFIRM", comment: ""),
				sizeToFit: true
			)
			self.confirmPassword_label = view
			self.addSubview(view)
		}
	}
	//
	// Runtime - Accessors - Derived properties
	
	//
	// Imperatives - Overrides - Interactivity
	override func disable()
	{
		self.password_inputView.isEnabled = false
		self.confirmPassword_inputView.isEnabled = false
	}
	override func reEnable()
	{
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
	// Overrides - Imperatives - UIKit
	override func layoutSubviews()
	{
		super.layoutSubviews()
		//
		let self_frame = self.frame
		let topPadding: CGFloat = 20
		let textField_x: CGFloat = CGFloat.form_input_margin_x
		let labels_x: CGFloat  = CGFloat.form_label_margin_x
		let textField_w: CGFloat = self_frame.size.width - 2 * textField_x
		do {
			self.password_label.frame = CGRect(
				x: labels_x,
				y: topPadding,
				width: textField_w,
				height: self.password_label.frame.size.height
			)
			self.password_inputView.frame = CGRect(
				x: textField_x,
				y: self.password_label.frame.origin.y + self.password_label.frame.size.height + 8,
				width: textField_w,
				height: self.password_inputView.frame.size.height
			)
		}
		do {
			self.fieldAccessoryMessageLabel.frame = CGRect(
				x: labels_x,
				y: self.password_inputView.frame.origin.y + self.password_inputView.frame.size.height + 7,
				width: textField_w,
				height: 0
			)
			self.fieldAccessoryMessageLabel.sizeToFit()
		}
		do {
			self.confirmPassword_label.frame = CGRect(
				x: labels_x,
				y: self.fieldAccessoryMessageLabel.frame.origin.y + self.fieldAccessoryMessageLabel.frame.size.height + 30,
				width: textField_w,
				height: self.confirmPassword_label.frame.size.height
			)
			self.confirmPassword_inputView.frame = CGRect(
				x: textField_x,
				y: self.confirmPassword_label.frame.origin.y + self.confirmPassword_label.frame.size.height + 8,
				width: textField_w,
				height: self.confirmPassword_inputView.frame.size.height
			)
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
		self.textFieldEventDelegate.aPasswordField_editingChanged()
	}
	//
	// Delegation - UITextField
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if self.password_inputView.isFirstResponder {
			self.confirmPassword_inputView.becomeFirstResponder()
			return false
		}
		self.textFieldEventDelegate.aPasswordField_didReturn()
		return false
	}
}
