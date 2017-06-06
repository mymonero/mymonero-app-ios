//
//  EnterExistingPasswordView.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/4/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit
//
class EnterExistingPasswordView: PasswordEntryScreenBaseView
{	var password_label: FormLabel!
	var password_inputView: FormInputField!
	var forgot_linkButtonView: LinkButtonView!
	//
	override func setup()
	{
		super.setup()
		//
		do {
			let view = FormInputField(
				placeholder: NSLocalizedString("So we know it's you", comment: "")
			)
			view.isSecureTextEntry = true
			view.keyboardType = PasswordController.shared.passwordType == PasswordController.PasswordType.PIN ? .numberPad : .default
			view.returnKeyType = .go
			view.addTarget(self, action: #selector(aPasswordField_editingChanged), for: .editingChanged)
			view.delegate = self
			self.password_inputView = view
			self.addSubview(view)
		}
		do {
			let view = FormLabel(
				title: PasswordController.shared.passwordType.humanReadableString.uppercased(),
				sizeToFit: true
			)
			self.password_label = view
			self.addSubview(view)
		}
		do {
			let view = LinkButtonView(mode: .mono_default, title: NSLocalizedString("Forgot?", comment: ""))
			view.addTarget(self, action: #selector(tapped_forgotButton), for: .touchUpInside)
			view.contentHorizontalAlignment = .right // so we can just set the width to whatever
			self.forgot_linkButtonView = view
			self.addSubview(view)
		}
	}
	//
	// Runtime - Accessors - Derived properties
	
	//
	// Overrides - Imperatives
	override func layoutSubviews()
	{
		super.layoutSubviews()
		//
		let textField_topMargin: CGFloat = 8
		let fieldGroup_h = self.password_label.frame.size.height + textField_topMargin + self.password_inputView.frame.size.height
		let fieldGroup_y = (self.frame.size.height - fieldGroup_h) / 2
		let textField_x: CGFloat = CGFloat.form_input_margin_x
		let labels_x: CGFloat  = CGFloat.form_label_margin_x
		let textField_w: CGFloat = self.frame.size.width - 2 * textField_x
		do {
			self.password_label.frame = CGRect(
				x: labels_x,
				y: fieldGroup_y,
				width: self.frame.size.width - 2 * labels_x,
				height: self.password_label.frame.size.height
			)
			assert(self.forgot_linkButtonView.frame.size.height > self.password_label.frame.size.height, "self.forgot_linkButtonView.frame.size.height <= self.password_label.frame.size.height")
			self.forgot_linkButtonView.frame = CGRect(
				x: textField_x + textField_w - self.forgot_linkButtonView.frame.size.width - fabs(labels_x - textField_x),
				y: self.password_label.frame.origin.y - fabs(self.forgot_linkButtonView.frame.size.height - self.password_label.frame.size.height)/2, // since this button is taller than the label, we can't use the same y offset; we have to vertically center the forgot_linkButtonView with the label
				width: self.forgot_linkButtonView.frame.size.width,
				height: self.forgot_linkButtonView.frame.size.height
			)
			self.password_inputView.frame = CGRect(
				x: textField_x,
				y: self.password_label.frame.origin.y + self.password_label.frame.size.height + textField_topMargin,
				width: textField_w,
				height: self.password_inputView.frame.size.height
			)
		}
	}
	//
	// Imperatives - Overrides - Interactivity
	override func disable()
	{
		self.password_inputView.isEnabled = false
		self.forgot_linkButtonView.isEnabled = false
	}
	override func reEnable()
	{
		self.password_inputView.isEnabled = true
		self.password_inputView.becomeFirstResponder() // since disable would have de-focused
		self.forgot_linkButtonView.isEnabled = true
	}
	//
	// Overrides - Imperatives - Validation
	override func setValidationMessage(_ message: String)
	{
		self.password_inputView.setValidationError(message)
	}
	override func clearValidationMessage()
	{
		self.password_inputView.clearValidationError()
	}
	//
	// Delegation - Interactions
	@objc
	func tapped_forgotButton()
	{
		assert(false, "TODO")
	}
	//
	// Delegation - Password field - Control events
	@objc func aPasswordField_editingChanged()
	{
		if let textFieldEventDelegate = self.textFieldEventDelegate {
			textFieldEventDelegate.aPasswordField_editingChanged()
		}
	}
	// Delegation - UITextField
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		self.textFieldEventDelegate.aPasswordField_didReturn()
		return false
	}
}
