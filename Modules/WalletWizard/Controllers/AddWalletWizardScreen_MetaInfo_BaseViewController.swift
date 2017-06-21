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
	var walletLabel_label: UICommonComponents.FormLabel!
	var walletLabel_inputView: UICommonComponents.FormInputField!
	//
	var walletColorPicker_label: UICommonComponents.FormLabel!
	var walletColorPicker_inputView: UICommonComponents.WalletColorPickerView!
	//
	override func setup_views()
	{
		do { // validation message view
			DDLog.Todo("WalletWizard", "implement validation msg view")
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
				view.isSecureTextEntry = true
				view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				view.delegate = self
				view.returnKeyType = .next
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
//				view.delegate = self
				self.walletColorPicker_inputView = view
				self.view.addSubview(view)
			}
		}
	}
	//
	// Runtime - Imperatives - Convenience - Layout
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
}
