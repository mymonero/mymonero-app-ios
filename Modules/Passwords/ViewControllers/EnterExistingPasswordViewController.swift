//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class EnterExistingPasswordViewController: PasswordEntryScreenBaseViewController
{
	var password_label: UICommonComponents.FormLabel!
	var password_inputView: UICommonComponents.FormInputField!
	var forgot_linkButtonView: UICommonComponents.LinkButtonView!
	//
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("So we know it's you", comment: "")
			)
			view.isSecureTextEntry = true
			view.keyboardType = PasswordController.shared.passwordType == PasswordController.PasswordType.PIN ? .numberPad : .default
			view.returnKeyType = .go
			view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			view.delegate = self
			self.password_inputView = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormLabel(
				title: PasswordController.shared.passwordType.humanReadableString.uppercased(),
				sizeToFit: true
			)
			self.password_label = view
			self.view.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("Forgot?", comment: ""))
			view.addTarget(self, action: #selector(tapped_forgotButton), for: .touchUpInside)
			view.contentHorizontalAlignment = .right // so we can just set the width to whatever
			self.forgot_linkButtonView = view
			self.view.addSubview(view)
		}
	}
	override func setup_navigation()
	{
		self.navigationItem.title = NSLocalizedString("Enter \(PasswordController.shared.passwordType.capitalized_humanReadableString)", comment: "")
		self.navigationItem.leftBarButtonItem = self._new_leftBarButtonItem()
		self.navigationItem.rightBarButtonItem = self._new_rightBarButtonItem()
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
		let passwordInputValue = self.password_inputView.text
		item.isEnabled = passwordInputValue != nil && passwordInputValue != "" // need to enter PW first
		//
		return item
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		let password = self.password_inputView.text
		//
		return (password != nil && password != "") ? true : false
	}
	override func new_wantsBackgroundTapToFocusResponder_orNilToBlurInstead() -> UIResponder?
	{
		return self.password_inputView
	}
	//
	// Imperatives
	override func _tryToSubmitForm()
	{
		self.disableForm()
		// we can assume pw is not "" here
		self.__yield_nonZeroPassword()
	}
	func __yield_nonZeroPassword()
	{
		if let cb = userSubmittedNonZeroPassword_cb {
			cb(self.password_inputView.text!)
		}
	}
	override func disableForm()
	{
		super.disableForm()
		//
		self.password_inputView.isEnabled = false
		self.forgot_linkButtonView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
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
		self.password_inputView.becomeFirstResponder()
	}
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let textField_w = self.new__textField_w
		let textField_topMargin: CGFloat = UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView
		let fieldGroup_h = self.password_label.frame.size.height + textField_topMargin + self.password_inputView.frame.size.height
		let fieldGroup_y = (self.view.frame.size.height - fieldGroup_h)/2 - self.view.frame.size.height*0.1 // -k to work better on mobile screen
		//
		self.password_label.frame = CGRect(
			x: CGFloat.form_label_margin_x,
			y: fieldGroup_y,
			width: self.view.frame.size.width - 2 * CGFloat.form_label_margin_x,
			height: self.password_label.frame.size.height
		).integral
		assert(self.forgot_linkButtonView.frame.size.height > self.password_label.frame.size.height, "self.forgot_linkButtonView.frame.size.height <= self.password_label.frame.size.height")
		self.forgot_linkButtonView.frame = CGRect(
			x: CGFloat.form_input_margin_x + textField_w - self.forgot_linkButtonView.frame.size.width - fabs(CGFloat.form_label_margin_x - CGFloat.form_input_margin_x),
			y: self.password_label.frame.origin.y - fabs(self.forgot_linkButtonView.frame.size.height - self.password_label.frame.size.height)/2, // since this button is taller than the label, we can't use the same y offset; we have to vertically center the forgot_linkButtonView with the label
			width: self.forgot_linkButtonView.frame.size.width,
			height: self.forgot_linkButtonView.frame.size.height
		).integral
		self.password_inputView.frame = CGRect(
			x: CGFloat.form_input_margin_x,
			y: self.password_label.frame.origin.y + self.password_label.frame.size.height + textField_topMargin,
			width: textField_w,
			height: self.password_inputView.frame.size.height
		).integral
	}
	//
	// Delegation - Interactions
	@objc
	func tapped_forgotButton()
	{
		let controller = ForgotPasswordViewController()
		DispatchQueue.main.async { // to avoid animation jank (TODO: does this actually work? is this a problem on-device?); possibly exists due to time needed to lay out emoji label
			self.navigationController!.pushViewController(controller, animated: true)
		}
	}

}
