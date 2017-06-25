//
//  AddWalletWizardScreen_MetaInfo_BaseViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

class AddWalletWizardScreen_MetaInfo_BaseViewController: AddWalletWizardScreen_BaseViewController
{
	//
	// Properties
	var messageView: UICommonComponents.InlineMessageView!
	//
	var walletLabel_label: UICommonComponents.FormLabel!
	var walletLabel_inputView: UICommonComponents.FormInputField!
	//
	var walletColorPicker_label: UICommonComponents.FormLabel!
	var walletColorPicker_inputView: UICommonComponents.WalletColorPickerView!
	//
	override func setup_views()
	{
		do {
			let view = UICommonComponents.InlineMessageView(
				didHide:
				{ [unowned self] in
					self.view.setNeedsLayout()
				}
			)
			self.messageView = view
			self.view.addSubview(view)
		}
		super.setup_views()
		do { // wallet label field
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("WALLET NAME", comment: ""),
					sizeToFit: true
				)
				self.walletLabel_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("For your reference", comment: "")
				)
				view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				view.delegate = self
				view.returnKeyType = .go
				self.walletLabel_inputView = view
				self.view.addSubview(view)
			}
		}
		do { // wallet color field
			do {
				let view = UICommonComponents.FormLabel(
					title: NSLocalizedString("COLOR", comment: ""),
					sizeToFit: true
				)
				self.walletColorPicker_label = view
				self.view.addSubview(view)
			}
			do {
				let view = UICommonComponents.WalletColorPickerView(optl__currentlySelected_color: nil)
				self.walletColorPicker_inputView = view
				self.view.addSubview(view)
			}
		}
	}
	//
	// Accessors - Lookups/Derived - Input values
	var walletLabel: String? {
		return self.walletLabel_inputView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	//
	// Accessors - Lookups/Derived - Layout metrics
	var topPadding: CGFloat
	{
		return 13
	}
	var yOffsetForViewsBelowValidationMessageView: CGFloat
	{
		return self.messageView.isHidden ? self.topPadding : self.topPadding + self.messageView.frame.size.height + self.topPadding
	}
	//
	// Imperatives - Overrides - Validation
	override func setValidationMessage(_ message: String)
	{
		let view = self.messageView! // this ! is not necessary according to the var's optionality but there seems to be a compiler bug
		view.set(text: message)
		self.layOut_messageView() // this can be slightly redundant, but it is called here so we lay out before showing. maybe rework this so it doesn't require laying out twice and checking visibility. maybe a flag saying "ought to be showing". maybe.
		view.show()
		self.view.setNeedsLayout() // so views (below messageView) get re-laid-out
	}
	override func clearValidationMessage()
	{
		self.messageView.clearAndHide() // as you can see, no ! required here. compiler bug?
		// we don't need to call setNeedsLayout() here b/c the messageView callback in self.setup will do so
	}
	//
	// Imperatives - Convenience - Layout
	func layOut_walletLabelAndSwatchFields(atYOffset y: CGFloat)
	{ // Call this at the end of your layoutSubviews() override
		let textField_w = self.new__textField_w
		let fieldset_topMargin: CGFloat = UICommonComponents.FormLabel.marginAboveLabelForUnderneathField_textInputView + 8 // 8 for greater visual separation, per design; maybe factor
		do {
			self.walletLabel_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: y + fieldset_topMargin,
				width: textField_w,
				height: self.walletLabel_label.frame.size.height
			).integral
			self.walletLabel_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.walletLabel_label.frame.origin.y + self.walletLabel_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.walletLabel_inputView.frame.size.height
			).integral
		}
		do {
			self.walletColorPicker_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: self.walletLabel_inputView.frame.origin.y + self.walletLabel_inputView.frame.size.height + fieldset_topMargin + 3, // 3 for greater visual separation, per design
				width: textField_w,
				height: self.walletColorPicker_label.frame.size.height
			).integral
			//
			let colorPicker_x = CGFloat.form_input_margin_x
			let colorPicker_maxWidth = self.view.frame.size.width - colorPicker_x
			let colorPicker_height = self.walletColorPicker_inputView.heightThatFits(width: colorPicker_maxWidth)
			self.walletColorPicker_inputView.frame = CGRect(
				x: colorPicker_x,
				y: self.walletColorPicker_label.frame.origin.y + self.walletColorPicker_label.frame.size.height + UICommonComponents.FormLabel.marginBelowLabelAboveTextInputView,
				width: colorPicker_maxWidth,
				height: colorPicker_height
			).integral
		}
	}
	//
	// Imperatives - Internal - Layout
	func layOut_messageView()
	{
		let x = CGFloat.visual__form_input_margin_x // use visual__ instead so we don't get extra img padding
		let w = self.new__textField_w
		self.messageView.layOut(atX: x, y: self.topPadding, width: w)
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		if self.messageView.shouldPerformLayOut {
			self.layOut_messageView()
		}
	}
}
