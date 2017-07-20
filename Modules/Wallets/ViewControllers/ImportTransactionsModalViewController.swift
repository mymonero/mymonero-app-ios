//
//  ImportTransactionsModalViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/20/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import UIKit

struct ImportTransactionsModal {}

extension ImportTransactionsModal
{
	class ViewController: UICommonComponents.FormViewController
	{
		//
		// Properties
		// - Initializing
		var wallet: Wallet
		//
		// - Views
		var informationalLabel: UICommonComponents.FormAccessoryMessageLabel!
		//
		// TODO: tooltip
		//
		var fromWallet_label: UICommonComponents.Form.FieldLabel!
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonView!
		//
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_fieldset: UICommonComponents.Form.AmountInputFieldsetView!
		//
		var toAddress_label: UICommonComponents.Form.FieldLabel!
		var toAddress_labelAccessory_copyButton: UICommonComponents.CopyButton!
		var toAddress_inputView: UICommonComponents.FormInputField!
		//
		var paymentID_label: UICommonComponents.Form.FieldLabel!
		var paymentID_labelAccessory_copyButton: UICommonComponents.CopyButton!
		var paymentID_inputView: UICommonComponents.FormInputField!
		//
		// Lifecycle - Init
		init(wallet: Wallet)
		{
			self.wallet = wallet 
			super.init()
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup_views()
		{
			super.setup_views()
			do {
				let view = UICommonComponents.FormAccessoryMessageLabel(
					text: "" // for now … we will show 'loading' and then the final results
				)
				self.informationalLabel = view
			}
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("FROM", comment: "")
				)
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.WalletPickerButtonView(selectedWallet: nil)
				self.fromWallet_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("AMOUNT", comment: "")
				)
				self.amount_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.AmountInputFieldsetView()
				let inputField = view.inputField
				inputField.isEnabled = false
				self.amount_fieldset = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("TO", comment: "")
				)
				self.toAddress_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.CopyButton()
//				view.contentHorizontalAlignment = .right // so we can just set the width to whatever
				self.toAddress_labelAccessory_copyButton = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: nil
				)
				let inputField = view
				inputField.isEnabled = false
				self.toAddress_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("PAYMENT ID", comment: "")
				)
				self.paymentID_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.CopyButton()
//				view.contentHorizontalAlignment = .right // so we can just set the width to whatever
				self.paymentID_labelAccessory_copyButton = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: nil
				)
				let inputField = view
				inputField.isEnabled = false
				self.paymentID_inputView = view
				self.scrollView.addSubview(view)
			}
		}
		override func setup_navigation()
		{
			super.setup_navigation()
			self.navigationItem.title = NSLocalizedString("Import Transactions", comment: "")
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .send,
				target: self,
				action: #selector(tapped_rightBarButtonItem)
			)
			self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .cancel,
				target: self,
				action: #selector(tapped_barButtonItem_cancel)
			)
		}
		//
		// Accessors - Overrides
		override func new_isFormSubmittable() -> Bool
		{
			if self.formSubmissionController != nil {
				return false
			}
			if self.amount_fieldset.inputField.submittableDouble_orNil == nil {
				// until it's filled with an amount
				return false // for ex if they just put in "."
			}
			assert(self.toAddress_inputView.text != nil && self.toAddress_inputView.text != "")
			assert(self.paymentID_inputView.text != nil && self.paymentID_inputView.text != "")
			// and since everything else is disabled, I'll presume no other validation necessary
			return true
		}
		//
		// Accessors - Overrides
		//
		// Accessors
		var sanitizedInputValue__toWallet: Wallet {
			return self.fromWallet_inputView.selectedWallet! // we are never expecting this modal to be visible when no wallets exist, so a crash is/ought to be ok
		}
		//
		// Runtime - Imperatives - Overrides
		override func disableForm()
		{
			super.disableForm()
			//
			self.scrollView.isScrollEnabled = false
			self.fromWallet_inputView.isEnabled = false
			// no need to redundantly disable other fixed-value input fields…
		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			self.scrollView.isScrollEnabled = true
			self.fromWallet_inputView.isEnabled = true
			// do not enable other fixed-value input fields…
		}
		var formSubmissionController: AddFundsRequestFormSubmissionController? // TODO: maybe standardize into FormViewController
		override func _tryToSubmitForm()
		{
			self.clearValidationMessage()
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			//
			// TODO get amt etc from data payload received from import req
//			let amount = self.amount_fieldset.inputField.text // we're going to allow empty amounts
//			let submittableDoubleAmount = self.amount_fieldset.inputField.submittableDouble_orNil
//			let parameters = AddFundsRequestFormSubmissionController.Parameters(
//				optl__toWallet_color: toWallet.swatchColor,
//				toWallet_address: toWallet.public_address,
//				optl__fromContact_name: fromContact_name_orNil,
//				paymentID: paymentID,
//				amount: amount,
//				optl__memo: memoString,
//				//
//				preSuccess_terminal_validationMessage_fn:
//				{ [unowned self] (localizedString) in
//					self.setValidationMessage(localizedString)
//					self.formSubmissionController = nil // must free as this is a terminal callback
//					self.set_isFormSubmittable_needsUpdate()
//					self.reEnableForm() // b/c we disabled it
//				},
//				success_fn:
//				{ [unowned self] (instance) in
//					self.formSubmissionController = nil // must free as this is a terminal callback
//					self.reEnableForm() // b/c we disabled it
//					self._didSave(instance: instance)
//				}
//			)
//			let controller = AddFundsRequestFormSubmissionController(parameters: parameters)
//			self.formSubmissionController = controller
//			do {
//				self.disableForm()
//				self.set_isFormSubmittable_needsUpdate() // update submittability
//			}
//			controller.handle()
		}
		//
		// Delegation - Form submission success
		func _didSend()
		{
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			//
			let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
			let textField_w = self.new__textField_w
			let fullWidth_label_w = self.new__fieldLabel_w
			//
			do {
				self.informationalLabel.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: ceil(top_yOffset),
					width: fullWidth_label_w,
					height: 0
				).integral
				self.informationalLabel.sizeToFit()
			}
			do {
				self.fromWallet_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.informationalLabel.text != nil && self.informationalLabel.text != "" ? self.informationalLabel.frame.origin.y + self.informationalLabel.frame.size.height + 24 : ceil(top_yOffset),
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
				).integral
				self.fromWallet_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.fromWallet_label.frame.origin.y + self.fromWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
					width: textField_w,
					height: self.fromWallet_inputView.frame.size.height
				).integral
			}
			do {
				self.amount_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
					).integral
				self.amount_fieldset.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: self.amount_fieldset.frame.size.width,
					height: self.amount_fieldset.frame.size.height
					).integral
			}
			do {
				self.toAddress_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimate margin
					width: fullWidth_label_w,
					height: self.toAddress_label.frame.size.height
				).integral
				self.toAddress_labelAccessory_copyButton.frame = CGRect(
					x: CGFloat.form_labelAccessoryLabel_margin_x + fullWidth_label_w - self.toAddress_labelAccessory_copyButton.frame.size.width/2 - self.toAddress_labelAccessory_copyButton.titleLabel!.frame.size.width/2,
					y: self.toAddress_label.frame.origin.y - (self.toAddress_labelAccessory_copyButton.frame.size.height - self.toAddress_label.frame.size.height)/2,
					width: self.toAddress_labelAccessory_copyButton.frame.size.width,
					height: self.toAddress_labelAccessory_copyButton.frame.size.height
				).integral
				self.toAddress_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.toAddress_label.frame.origin.y + self.toAddress_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.toAddress_inputView.frame.size.height
				).integral
			}
			do {
				self.paymentID_label.frame = CGRect(
					x: CGFloat.form_label_margin_x,
					y: self.toAddress_inputView.frame.origin.y + self.toAddress_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimate margin
					width: fullWidth_label_w,
					height: self.paymentID_label.frame.size.height
				).integral
				self.paymentID_labelAccessory_copyButton.frame = CGRect(
					x: CGFloat.form_labelAccessoryLabel_margin_x + fullWidth_label_w - self.paymentID_labelAccessory_copyButton.frame.size.width/2 - self.toAddress_labelAccessory_copyButton.titleLabel!.frame.size.width/2,
					y: self.paymentID_label.frame.origin.y - (self.paymentID_labelAccessory_copyButton.frame.size.height - self.paymentID_label.frame.size.height)/2,
					width: self.paymentID_labelAccessory_copyButton.frame.size.width,
					height: self.paymentID_labelAccessory_copyButton.frame.size.height
				).integral
				self.paymentID_inputView.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: self.paymentID_label.frame.origin.y + self.paymentID_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.paymentID_inputView.frame.size.height
				).integral
			}
			let bottomMostView = self.paymentID_inputView!
			let bottomPadding: CGFloat = 18
			self.scrollableContentSizeDidChange(
				withBottomView: bottomMostView,
				bottomPadding: bottomPadding
			)
		}
		//
		// Delegation - Interactions
		func tapped_rightBarButtonItem()
		{
			self.aFormSubmissionButtonWasPressed()
		}
		func tapped_barButtonItem_cancel()
		{
			assert(self.navigationController!.presentingViewController != nil)
			// we always expect self to be presented modally
			self.navigationController?.dismiss(animated: true, completion: nil)
		}
	}
}
