//
//  AddWalletWizardScreen_MetaInfo_BaseViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 6/19/17.
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
					title: NSLocalizedString("WALLET NAME", comment: "")
				)
				self.walletLabel_label = view
				self.scrollView.addSubview(view)
			}
			do { // TODO: Factor this and share it with AddWalletWizardScreen ?
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("For your reference", comment: "")
				)
				view.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
				view.delegate = self
				view.autocapitalizationType = .words
				view.returnKeyType = .go
				self.walletLabel_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		do { // wallet color field
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("COLOR", comment: "")
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
	func layOut_walletLabelAndSwatchFields(
		atYOffset y: CGFloat,
		isTopMostInForm: Bool = false
	)
	{ // Call this at the end of your layoutSubviews() override
		let label_x = self.new__label_x
		let input_x = self.new__input_x
		let textField_w = self.new__textField_w
		let fieldset_topMargin: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // what we would expect for a starting y offset for form fields…
		do {
			self.walletLabel_label.frame = CGRect(
				x: label_x,
				y: y + fieldset_topMargin,
				width: textField_w,
				height: self.walletLabel_label.frame.size.height
			).integral
			self.walletLabel_inputView.frame = CGRect(
				x: input_x,
				y: self.walletLabel_label.frame.origin.y + self.walletLabel_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.walletLabel_inputView.frame.size.height
			).integral
		}
		do {
			self.walletColorPicker_label.frame = CGRect(
				x: label_x,
				y: self.walletLabel_inputView.frame.origin.y + self.walletLabel_inputView.frame.size.height + fieldset_topMargin,
				width: textField_w,
				height: self.walletColorPicker_label.frame.size.height
			).integral
			//
			let colorPicker_x = input_x
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
