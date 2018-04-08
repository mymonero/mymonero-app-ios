//
//  EnterExistingPasswordViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/3/17.
//  Copyright (c) 2014-2018, MyMonero.com
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of
//	conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list
//	of conditions and the following disclaimer in the documentation and/or other
//	materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be
//	used to endorse or promote products derived from this software without specific
//	prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
import UIKit

class EnterExistingPasswordViewController: PasswordEntryScreenBaseViewController
{
	var password_label: UICommonComponents.Form.FieldLabel!
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
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: PasswordController.shared.passwordType.humanReadableString.uppercased()
			)
			self.password_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, title: NSLocalizedString("Forgot?", comment: ""))
			view.addTarget(self, action: #selector(tapped_forgotButton), for: .touchUpInside)
			view.contentHorizontalAlignment = .right // so we can just set the width to whatever
			self.forgot_linkButtonView = view
			self.scrollView.addSubview(view)
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
		// no need to place this on super's 'really_clear' timer
		self.password_inputView.clearValidationError()
	}
	//
	// Delegation - Navigation bar buttons
	@objc func tapped_leftBarButtonItem()
	{
		if let cb = self.cancelButtonPressed_cb {
			cb()
		}
	}
	@objc func tapped_rightBarButtonItem()
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
		let label_x = self.new__label_x
		let input_x = self.new__input_x
		let textField_w = self.new__textField_w // already has customInsets subtracted
		//
		let textField_topMargin: CGFloat = UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView
		let fieldGroup_h = self.password_label.frame.size.height + textField_topMargin + self.password_inputView.frame.size.height
		let fieldGroup_y = (self.scrollView.frame.size.height - fieldGroup_h)/2 - self.scrollView.frame.size.height*0.15 // -k to work better on mobile screen
		//
		self.password_label.frame = CGRect(
			x: label_x,
			y: fieldGroup_y,
			width: self.scrollView.frame.size.width - 2 * label_x,
			height: self.password_label.frame.size.height
		).integral
		assert(self.forgot_linkButtonView.frame.size.height > self.password_label.frame.size.height, "self.forgot_linkButtonView.frame.size.height <= self.password_label.frame.size.height")
		self.forgot_linkButtonView.frame = CGRect(
			x: input_x + textField_w - self.forgot_linkButtonView.frame.size.width - fabs(label_x - input_x),
			y: self.password_label.frame.origin.y - fabs(self.forgot_linkButtonView.frame.size.height - self.password_label.frame.size.height)/2, // since this button is taller than the label, we can't use the same y offset; we have to vertically center the forgot_linkButtonView with the label
			width: self.forgot_linkButtonView.frame.size.width,
			height: self.forgot_linkButtonView.frame.size.height
		).integral
		self.password_inputView.frame = CGRect(
			x: input_x,
			y: self.password_label.frame.origin.y + self.password_label.frame.size.height + textField_topMargin,
			width: textField_w,
			height: self.password_inputView.frame.size.height
		).integral
	}
	//
	// Delegation - Interactions
	@objc func tapped_forgotButton()
	{
		let controller = ForgotPasswordViewController()
		DispatchQueue.main.async
		{ [unowned self] in // to avoid animation jank (TODO: does this actually work? is this a problem on-device?); possibly exists due to time needed to lay out emoji label
			self.navigationController!.pushViewController(controller, animated: true)
		}
	}

}
