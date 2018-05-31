//
//  ImportTransactionsModalViewController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 7/20/17.
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

struct ImportTransactionsModal {}

extension ImportTransactionsModal
{
	class ViewController: UICommonComponents.FormViewController
	{
		//
		// Properties
		// - Initializing
		var wallet: Wallet // leaving this as a strong ref b/c self should be torn down  
		//
		// - Views
		var informationalLabel: UICommonComponents.FormAccessoryMessageLabel!
		var informationalLabel_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var fromWallet_label: UICommonComponents.Form.FieldLabel!
		var fromWallet_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonFieldView!
		//
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_fieldset: UICommonComponents.Form.Amounts.InputFieldsetView!
		//
		var toAddress_label: UICommonComponents.Form.FieldLabel!
		var toAddress_labelAccessory_copyButton: UICommonComponents.SmallUtilityCopyValueButton!
		var toAddress_inputView: UICommonComponents.FormInputField!
		//
		var paymentID_label: UICommonComponents.Form.FieldLabel!
		var paymentID_labelAccessory_copyButton: UICommonComponents.SmallUtilityCopyValueButton!
		var paymentID_inputView: UICommonComponents.FormInputField!
		//
		let note_messageView = UICommonComponents.InlineMessageView(mode: .noCloseButton)
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
			//
			let approximate_importOAAddress: String = SettingsController.shared.specificAPIAddressURLAuthority != nil
				? "import.\(SettingsController.shared.specificAPIAddressURLAuthority!)" // this is obvs 'approximate' and only meant to be used as an example…… if specificAPIAddressURLAuthority contains a port or a subdomain then this will appear to be obviously wrong but still server its purpose as an example to the power user who is entering a custom server address
				: HostedMonero.APIClient.mymonero_importFeeSubmissionTarget_openAliasAddress
			//
			do {
				let view = UICommonComponents.FormAccessoryMessageLabel(
					text: NSLocalizedString("Loading…", comment: "") // for now…
				)
				self.informationalLabel = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"Importing your wallet means the server will scan the entire Monero blockchain for your wallet's past transactions, then stay up-to-date.\n\nAs this process places heavy load on the server, import is triggered by sending a fee with the specific payment ID below to the server at e.g. \(approximate_importOAAddress).",
						comment: ""
					)
				)
				view.tooltipDirectionFromOrigin = .left // b/c we're at the top of the screen but also so close to the right side - would be nice to be able to go down-left - but since the right edge/space ends up being the limiting factor, we must choose .left instead of .down
				view.isHidden = true // initially
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.informationalLabel_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("FROM", comment: "")
				)
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: NSLocalizedString(
						"For convenience you may send the fee from MyMonero here, or the official CLI or GUI tools, or any other Monero wallet.\n\nPlease be sure to use the exact payment ID below, so the server knows which wallet to import.",
						comment: ""
					)
				)
				view.tooltipDirectionFromOrigin = .right // too close to top of screen - and .down does not support iphone X safe areas (in this case) due to width
				//
				view.isHidden = true // initially
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.fromWallet_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			do {
				// TODO? attempt to pick sensible wallet based on balance?
				let view = UICommonComponents.WalletPickerButtonFieldView(selectedWallet: nil)
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
				let view = UICommonComponents.Form.Amounts.InputFieldsetView(
					effectiveAmountLabelBehavior: .undefined // .none b/c we never display anything but .XMR here so far
				)
				let inputField = view.inputField
				inputField.isEnabled = false
				inputField.isImmutable = true
				view.currencyPickerButton.isEnabled = false
				view.currencyPickerButton.set(
					selectedCurrency: .XMR,
					skipSettingOnPickerView: false/*ofc*/
				)
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
				let view = UICommonComponents.SmallUtilityCopyValueButton()
//				view.contentHorizontalAlignment = .right // so we can just set the width to whatever
				self.toAddress_labelAccessory_copyButton = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.FormInputField(
					placeholder: approximate_importOAAddress
				)
				let inputField = view
				inputField.isEnabled = false
				inputField.isImmutable = true
				self.toAddress_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("PAYMENT ID (REQUIRED)", comment: "")
				)
				self.paymentID_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.SmallUtilityCopyValueButton()
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
				inputField.isImmutable = true
				self.paymentID_inputView = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = self.note_messageView
				view.set(text: NSLocalizedString("NOTE: Don't transfer your wallet's balance to this address. (This isn't your new address.)", comment: ""))
				view.show()
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
		// Lifecycle - Deinit
		deinit
		{
			self.teardown()
		}
		func teardown()
		{
			if self.importRequestInfoAndStatus_requestHandle != nil {
				self.importRequestInfoAndStatus_requestHandle!.cancel()
				self.importRequestInfoAndStatus_requestHandle = nil
			}
			if self.submissionController != nil {
				// TODO
//				self.submissionController!.cancel()
				self.submissionController = nil
			}
		}
		//
		// Accessors - Overrides
		override func new_isFormSubmittable() -> Bool
		{
			if self.submissionController != nil {
				return false
			}
			if self.importRequestInfoAndStatus_requestHandle != nil {
				return false
			}
			if self.importRequestInfoAndStatus_receivedResult == nil {
				return false // not yet received
			}
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
		// Imperatives - Import info request
		var hasAlreadyInitiatedRequest = false
		var importRequestInfoAndStatus_requestHandle: HostedMonero.APIClient.RequestHandle?
		var importRequestInfoAndStatus_receivedResult: HostedMonero.ParsedResult_ImportRequestInfoAndStatus?
		func doDataRequest_ifNecessary()
		{
			if self.hasAlreadyInitiatedRequest {
				return
			}
			self.hasAlreadyInitiatedRequest = true
			assert(self.importRequestInfoAndStatus_requestHandle == nil)
			self.importRequestInfoAndStatus_requestHandle = HostedMonero.APIClient.shared.ImportRequestInfoAndStatus(
				address: self.wallet.public_address,
				view_key__private: self.wallet.private_keys.view
			)
			{ (err_str, result) in
				self.importRequestInfoAndStatus_requestHandle = nil // regardless
				if err_str != nil {
					self.informationalLabel.text = "" // clear for now
					self.setValidationMessage(err_str!) // will also call setNeedsLayout for us
					return
				}
				self.importRequestInfoAndStatus_receivedResult = result
				self.configureWithInfoRequestResult()
			}
		}
		func configureWithInfoRequestResult()
		{
			self.clearValidationMessage()
			self.set_isFormSubmittable_needsUpdate() // enable submission
			//
			let result = self.importRequestInfoAndStatus_receivedResult!
			let payment_id = result.payment_id
			let payment_address = result.payment_address
			let import_fee = result.import_fee
			let feeReceiptStatus = result.feeReceiptStatus
			//
			let formatted_importFee = import_fee.localized_formattedString
			do {
				self.informationalLabel.setMessageText(
					String(
						format: NSLocalizedString(
							"This requires a one-time import fee of %@ XMR", // no break spaces btwn of and amt and amt and ccy 
							comment: ""
						),
						formatted_importFee
					) + (
						feeReceiptStatus != nil ? "\n(Status: \(feeReceiptStatus!).)" : ""
					)
				)
				self.informationalLabel_tooltipSpawn_buttonView.isHidden = false // show
			}
			do {
				self.fromWallet_tooltipSpawn_buttonView.isHidden = false
			}
			do {
				self.toAddress_inputView.text = payment_address
				self.toAddress_labelAccessory_copyButton.set(text: payment_address)
				//
				self.paymentID_inputView.text = payment_id
				self.paymentID_labelAccessory_copyButton.set(text: payment_id)
				//
				var amountStr = formatted_importFee
				let locale_decimalSeparator = Locale.current.decimalSeparator ?? "."
				if amountStr.contains(locale_decimalSeparator) == false {
					amountStr += locale_decimalSeparator + "00"
				}
				if amountStr.first == locale_decimalSeparator.first! { // checking, in case amountStr < 1.0
					amountStr = "0" + amountStr
				}
				self.amount_fieldset.inputField.text = amountStr
				self.amount_fieldset.currencyPickerButton.set( // just to be explicit
					selectedCurrency: .XMR,
					skipSettingOnPickerView: false
				)
			}
			//
			self.view.setNeedsLayout() // important
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
			//
			// and, b/c SendFunds is not yet coded to allow cancellation, we temporarily disable cancel here to prevent the user from accidentally sending redundant funds
			self.navigationItem.leftBarButtonItem?.isEnabled = false

		}
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			self.scrollView.isScrollEnabled = true
			self.fromWallet_inputView.isEnabled = true
			// do not enable other fixed-value input fields…
			//
			// must re-enable cancel btn
			self.navigationItem.leftBarButtonItem?.isEnabled = true
		}
		var submissionController: ImportTransactionsModal.SubmissionController? // TODO: maybe standardize into FormViewController
		override func _tryToSubmitForm()
		{
			if self.submissionController != nil {
				assert(false) // should be impossible
				return
			}
			do {
				self.set(
					validationMessage: NSLocalizedString(
						"Sending \(self.importRequestInfoAndStatus_receivedResult!.import_fee.localized_formattedString) XMR…",
						comment: ""
					),
					wantsXButton: false
				)
			}
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			let result = self.importRequestInfoAndStatus_receivedResult!
			let parameters = ImportTransactionsModal.SubmissionController.Parameters(
				fromWallet: fromWallet,
				infoRequestParsingResult: result,
				preSuccess_nonTerminal_validationMessageUpdate_fn:
				{ [weak self] (localizedString) in
					guard let thisSelf = self else {
						return
					}
					thisSelf.set(validationMessage: localizedString, wantsXButton: false)
				},
				preSuccess_terminal_validationMessage_fn:
				{ [weak self] (localized_errStr) in
					guard let thisSelf = self else {
						return
					}
					thisSelf.reEnableForm() // important
					thisSelf.set(validationMessage: localized_errStr, wantsXButton: false)
				},
				canceled_fn:
				{ [weak self] in
					guard let thisSelf = self else {
						return
					}
					thisSelf.reEnableForm() // important
					thisSelf.clearValidationMessage() // un-set "Sending... "
				})
				{ [weak self] in // success
					guard let thisSelf = self else {
						return
					}
					thisSelf.submissionController = nil // free
					thisSelf.set(
						validationMessage: NSLocalizedString("Sent!", comment: ""),
						wantsXButton: false
					)
					DispatchQueue.main.asyncAfter( 
						deadline: .now() + 1.0, // for effect
						execute:
						{ [weak self] in // Now dismiss
							guard let thisSelf = self else {
								return
							}
							thisSelf.navigationController?.dismiss(animated: true, completion: nil)
						}
					)
					DispatchQueue.main.async
					{ // and fire off a request to have the wallet get the latest (real) tx records
						fromWallet.hostPollingController!._fetch_addressTransactions() // TODO: maybe fix up the API for this
					}					
				}
			let controller = ImportTransactionsModal.SubmissionController(parameters: parameters)
			self.submissionController = controller
			do {
				self.disableForm()
				self.set_isFormSubmittable_needsUpdate() // update submittability; after setting self.submissionController
			}
			controller.handle()
		}
		//
		// Delegation - Form submission success
		func _didSend()
		{
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			self.informationalLabel_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
			self.fromWallet_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
		}
		//
		// Delegation - View
		override func viewDidLayoutSubviews()
		{
			super.viewDidLayoutSubviews()
			//
			let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
			let label_x = self.new__label_x
			let labelAccessoryLabel_x = self.new__labelAccessoryLabel_x
			let input_x = self.new__input_x
			let textField_w = self.new__textField_w
			let fullWidth_label_w = self.new__fieldLabel_w
			//
			do {
				let max_w = textField_w
				self.informationalLabel.frame = CGRect(
					x: 0,
					y: 0,
					width: max_w,
					height: 0
				).integral
				self.informationalLabel.sizeToFit() // for centering
				let w = self.informationalLabel.frame.size.width
				self.informationalLabel.frame = CGRect(
					x: (max_w - w)/2 + input_x,
					y: top_yOffset,
					width: w,
					height: self.informationalLabel.frame.size.height // read height
				).integral
			}
			do {
				if self.informationalLabel_tooltipSpawn_buttonView.isHidden == false {
					let label = self.informationalLabel!
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.informationalLabel_tooltipSpawn_buttonView.frame = CGRect(
						x: label.frame.origin.x + label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: label.frame.origin.y - (tooltipSpawn_buttonView_h - label.frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
			}
			//
			do {
				self.fromWallet_label.frame = CGRect(
					x: label_x,
					y: self.informationalLabel.text != nil && self.informationalLabel.text != "" ? self.informationalLabel.frame.origin.y + self.informationalLabel.frame.size.height + 24 : top_yOffset,
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
				).integral
				do {
					let label = self.fromWallet_label!
					label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
					var final__label_frame = label.frame
					final__label_frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
					label.frame = final__label_frame // kinda sucks to set this three times in this method. any alternative?
					//
					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
					self.fromWallet_tooltipSpawn_buttonView.frame = CGRect(
						x: final__label_frame.origin.x + final__label_frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
						y: final__label_frame.origin.y - (tooltipSpawn_buttonView_h - final__label_frame.size.height)/2,
						width: tooltipSpawn_buttonView_w,
						height: tooltipSpawn_buttonView_h
					).integral
				}
				self.fromWallet_inputView.frame = CGRect(
					x: input_x,
					y: self.fromWallet_label.frame.origin.y + self.fromWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
					width: textField_w,
					height: type(of: self.fromWallet_inputView).fixedHeight
				).integral
			}
			do {
				self.amount_label.frame = CGRect(
					x: label_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
					width: fullWidth_label_w,
					height: self.fromWallet_label.frame.size.height
					).integral
				self.amount_fieldset.frame = CGRect(
					x: input_x,
					y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w, // full-size width
					height: UICommonComponents.Form.Amounts.InputFieldsetView.h
					).integral
			}
			do {
				self.toAddress_label.frame = CGRect(
					x: label_x,
					y: self.amount_fieldset.frame.origin.y + self.amount_fieldset.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimate margin
					width: fullWidth_label_w,
					height: self.toAddress_label.frame.size.height
				).integral
				self.toAddress_labelAccessory_copyButton.frame = CGRect(
					x: labelAccessoryLabel_x + fullWidth_label_w - self.toAddress_labelAccessory_copyButton.frame.size.width/2 - self.toAddress_labelAccessory_copyButton.titleLabel!.frame.size.width/2,
					y: self.toAddress_label.frame.origin.y - (self.toAddress_labelAccessory_copyButton.frame.size.height - self.toAddress_label.frame.size.height)/2,
					width: self.toAddress_labelAccessory_copyButton.frame.size.width,
					height: self.toAddress_labelAccessory_copyButton.frame.size.height
				).integral
				self.toAddress_inputView.frame = CGRect(
					x: input_x,
					y: self.toAddress_label.frame.origin.y + self.toAddress_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.toAddress_inputView.frame.size.height
				).integral
			}
			do {
				self.paymentID_label.frame = CGRect(
					x: label_x,
					y: self.toAddress_inputView.frame.origin.y + self.toAddress_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimate margin
					width: fullWidth_label_w,
					height: self.paymentID_label.frame.size.height
				).integral
				self.paymentID_labelAccessory_copyButton.frame = CGRect(
					x: labelAccessoryLabel_x + fullWidth_label_w - self.paymentID_labelAccessory_copyButton.frame.size.width/2 - self.toAddress_labelAccessory_copyButton.titleLabel!.frame.size.width/2,
					y: self.paymentID_label.frame.origin.y - (self.paymentID_labelAccessory_copyButton.frame.size.height - self.paymentID_label.frame.size.height)/2,
					width: self.paymentID_labelAccessory_copyButton.frame.size.width,
					height: self.paymentID_labelAccessory_copyButton.frame.size.height
				).integral
				self.paymentID_inputView.frame = CGRect(
					x: input_x,
					y: self.paymentID_label.frame.origin.y + self.paymentID_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: self.paymentID_inputView.frame.size.height
				).integral
			}
			do {
				self.note_messageView.layOut(atX: input_x, y: self.paymentID_inputView.frame.origin.y + self.paymentID_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, width: textField_w)
			}
			let bottomMostView = self.note_messageView
			let bottomPadding: CGFloat = 18
			self.scrollableContentSizeDidChange(
				withBottomView: bottomMostView,
				bottomPadding: bottomPadding
			)
		}
		//
		// Delegation - Interactions
		@objc func tapped_rightBarButtonItem()
		{
			self.aFormSubmissionButtonWasPressed()
		}
		@objc func tapped_barButtonItem_cancel()
		{
			assert(self.navigationController!.presentingViewController != nil)
			// we always expect self to be presented modally
			self.navigationController?.dismiss(animated: true, completion: nil)
		}
		//
		// Delegation
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			self.doDataRequest_ifNecessary()
		}
	}
}
