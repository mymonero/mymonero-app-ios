//
//  EditWalletViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/19/17.
//  Copyright (c) 2014-2017, MyMonero.com
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

struct EditWallet {}

extension EditWallet
{
	class ViewController: UICommonComponents.FormViewController
	{
		//
		// Properties
		var wallet: Wallet // think it should be fine if it's a strong reference since self will be torn down 
		//
		// Lifecycle - Init
		required init(wallet: Wallet)
		{
			self.wallet = wallet
			super.init()
		}
		required init?(coder aDecoder: NSCoder)
		{
			fatalError("init(coder:) has not been implemented")
		}
		//
		// Properties
		var walletLabel_label: UICommonComponents.Form.FieldLabel!
		var walletLabel_inputView: UICommonComponents.FormInputField!
		//
		var walletColorPicker_label: UICommonComponents.Form.FieldLabel!
		var walletColorPicker_inputView: UICommonComponents.WalletColorPickerView!
		//
		var deleteButton_separatorView: UICommonComponents.Details.FieldSeparatorView!
		var deleteButton: UICommonComponents.LinkButtonView!
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
				do { // TODO: Factor this and share it with WalletWizard ?
					let view = UICommonComponents.FormInputField(
						placeholder: NSLocalizedString("For your reference", comment: "")
					)
					view.text = self.wallet.walletLabel
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
					let view = UICommonComponents.WalletColorPickerView(
						optl__currentlySelected_color: self.wallet.swatchColor
					)
					self.walletColorPicker_inputView = view
					self.scrollView.addSubview(view)
				}
			}
			do {
				let view = UICommonComponents.Details.FieldSeparatorView(mode: .contentBackgroundAccent)
				self.deleteButton_separatorView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.LinkButtonView(mode: .mono_destructive, title: "REMOVE WALLET")
				view.addTarget(self, action: #selector(deleteButton_tapped), for: .touchUpInside)
				self.deleteButton = view
				self.scrollView.addSubview(view)
			}
		}
		override func setup_navigation()
		{
			super.setup_navigation()
			//
			self.navigationItem.title = NSLocalizedString("Edit Wallet", comment: "")
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .save,
				target: self,
				action: #selector(tapped_barButtonItem_save)
			)
		}
		//
		// Accessors - Lookups/Derived - Input values
		var walletLabel: String? {
			return self.walletLabel_inputView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
		}
		//
		// Accessors - Form submittable
		override func new_isFormSubmittable() -> Bool
		{
			if self.submissionController != nil {
				return false
			}
			guard let walletLabel = self.walletLabel, walletLabel != "" else {
				return false
			}
			return true
		}
		//
		// Imperatives - Modal
		func dismissModal()
		{
			self.navigationController?.dismiss(animated: true, completion: nil)
		}
		//
		// Runtime - Imperatives - Overrides
		override func disableForm()
		{
			super.disableForm()
			//
			self.scrollView.isScrollEnabled = false
			//
			self.walletColorPicker_inputView.set(isEnabled: false)
			self.walletLabel_inputView.isEnabled = false
		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			self.scrollView.isScrollEnabled = true
			//
			self.walletColorPicker_inputView.set(isEnabled: true)
			self.walletLabel_inputView.isEnabled = true
		}
		var submissionController: EditWallet.SubmissionController?
		override func _tryToSubmitForm()
		{
			if self.submissionController != nil {
				assert(false) // should be impossible
				return
			}
			let parameters = EditWallet.SubmissionController.Parameters(
				walletInstance: self.wallet,
				walletLabel: self.walletLabel!,
				swatchColor: self.walletColorPicker_inputView.currentlySelected_color!,
				preSuccess_terminal_validationMessage_fn:
				{ [unowned self] (localized_errStr) in
					self.setValidationMessage(localized_errStr)
				})
				{ (wallet) in
					// success
					self.submissionController = nil // free
					self.dismissModal()
				}
			let controller = EditWallet.SubmissionController(parameters: parameters)
			self.submissionController = controller
			controller.handle()
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			//
			let topPadding: CGFloat = 13
			let y: CGFloat = 0
			let textField_w = self.new__textField_w
			let fieldset_topMargin: CGFloat = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView // what we would expect for a starting y offset for form fields…
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
					y: self.walletLabel_inputView.frame.origin.y + self.walletLabel_inputView.frame.size.height + fieldset_topMargin,
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
			do {
				let justPreviousView = self.walletColorPicker_inputView!
				self.deleteButton_separatorView!.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: justPreviousView.frame.origin.y + justPreviousView.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
					width: self.scrollView.frame.size.width - 2 * CGFloat.form_input_margin_x,
					height: UICommonComponents.Details.FieldSeparatorView.h
				)
				//
				self.deleteButton!.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.deleteButton_separatorView!.frame.origin.y + self.deleteButton_separatorView!.frame.size.height + UICommonComponents.Form.FieldLabel.visual_marginAboveLabelForUnderneathField,
					width: self.deleteButton!.frame.size.width,
					height: self.deleteButton!.frame.size.height
				)
			}
			self.scrollableContentSizeDidChange(
				withBottomView: self.deleteButton,
				bottomPadding: topPadding
			)
		}
		//
		// Delegation - Interactions
		func tapped_barButtonItem_cancel()
		{
			self.dismissModal()
		}
		func tapped_barButtonItem_save()
		{
			self.aFormSubmissionButtonWasPressed()
		}
		//
		func deleteButton_tapped()
		{
			let alertController = UIAlertController(
				title: NSLocalizedString("Remove this wallet?", comment: ""),
				message: NSLocalizedString(
					"You are about to locally delete a wallet.\n\nMake sure you saved your mnemonic! It can be found by clicking the arrow next to Address on the Wallet screen. You will need it to recover access to this wallet.\n\nAre you sure you want to remove this wallet?",
					comment: ""
				),
				preferredStyle: .alert
			)
			alertController.addAction(
				UIAlertAction(
					title: NSLocalizedString("Remove", comment: ""),
					style: .destructive
				)
				{ (result: UIAlertAction) -> Void in
					let err_str = WalletsListController.shared.givenBooted_delete(listedObject: self.wallet)
					if err_str != nil {
						self.setValidationMessage(err_str!)
						return
					}
					assert(self.navigationController!.presentingViewController != nil)
					// we always expect self to be presented modally
					self.navigationController?.dismiss(animated: true, completion: nil)
				}
			)
			alertController.addAction(
				UIAlertAction(
					title: NSLocalizedString("Cancel", comment: ""),
					style: .default
				)
				{ (result: UIAlertAction) -> Void in
				}
			)
			self.navigationController!.present(alertController, animated: true, completion: nil)
		}
	}
}
