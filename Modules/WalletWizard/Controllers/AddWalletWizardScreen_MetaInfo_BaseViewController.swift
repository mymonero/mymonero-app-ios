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
	var walletLabel_label: UICommonComponents.Form.FieldLabel!
	var walletLabel_inputView: UICommonComponents.FormInputField!
	//
	var walletColorPicker_label: UICommonComponents.Form.FieldLabel!
	var walletColorPicker_inputView: UICommonComponents.WalletColorPickerView!
	//
	override func setup_views()
	{
		super.setup_views()
		do { // wallet label field
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("WALLET NAME", comment: ""),
					sizeToFit: true
				)
				self.walletLabel_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("For your reference", comment: "")
				)
				view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				view.delegate = self
				view.returnKeyType = .go
				self.walletLabel_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		do { // wallet color field
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("COLOR", comment: ""),
					sizeToFit: true
				)
				self.walletColorPicker_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.WalletColorPickerView(optl__currentlySelected_color: nil)
				self.walletColorPicker_inputView = view
				self.scrollView.addSubview(view)
			}
		}
	}
	//
	// Accessors - Lookups/Derived - Input values
	var walletLabel: String? {
		return self.walletLabel_inputView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	//
	// Imperatives - Convenience - Layout
	func layOut_walletLabelAndSwatchFields(atYOffset y: CGFloat)
	{ // Call this at the end of your layoutSubviews() override
		let textField_w = self.new__textField_w
		let fieldset_topMargin: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView + 8 // 8 for greater visual separation, per design; maybe factor
		do {
			self.walletLabel_label.frame = CGRect(
				x: CGFloat.form_label_margin_x,
				y: y + fieldset_topMargin,
				width: textField_w,
				height: self.walletLabel_label.frame.size.height
			).integral
			self.walletLabel_inputView.frame = CGRect(
				x: CGFloat.form_input_margin_x,
				y: self.walletLabel_label.frame.origin.y + self.walletLabel_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
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
			let colorPicker_maxWidth = self.scrollView.frame.size.width - colorPicker_x
			let colorPicker_height = self.walletColorPicker_inputView.heightThatFits(width: colorPicker_maxWidth)
			self.walletColorPicker_inputView.frame = CGRect(
				x: colorPicker_x,
				y: self.walletColorPicker_label.frame.origin.y + self.walletColorPicker_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: colorPicker_maxWidth,
				height: colorPicker_height
			).integral
		}
	}
}
