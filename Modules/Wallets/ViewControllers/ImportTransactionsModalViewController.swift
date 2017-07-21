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
					text: NSLocalizedString("Loading…", comment: "") // for now…
				)
				self.informationalLabel = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("FROM", comment: "")
				)
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do {
				// TODO? attempt to pick sensible wallet based on balance?
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
				inputField.placeholder = "import.mymonero.com"
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
		var importRequestInfoAndStatus_requestHandle: HostedMoneroAPIClient.RequestHandle?
		var importRequestInfoAndStatus_receivedResult: HostedMoneroAPIClient_Parsing.ParsedResult_ImportRequestInfoAndStatus?
		func doDataRequest_ifNecessary()
		{
			if self.hasAlreadyInitiatedRequest {
				return
			}
			self.hasAlreadyInitiatedRequest = true
			assert(self.importRequestInfoAndStatus_requestHandle == nil)
			self.importRequestInfoAndStatus_requestHandle = HostedMoneroAPIClient.shared.ImportRequestInfoAndStatus(
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
			let formatted_importFee = import_fee.humanReadableString
			do {
				self.informationalLabel.setMessageText(
					String(
						format: NSLocalizedString(
							"This requires a one-time import fee of %@ XMR",
							comment: ""
						),
						formatted_importFee
						) + (feeReceiptStatus != nil ? "\n(Status: \(feeReceiptStatus!).)" : "")
				)
				//
				// TODO
//				const tooltipText = "Importing your wallet means the server will scan the entire Monero blockchain for your wallet's past transactions, then stay up-to-date.<br/><br/>As this process is very server-intensive, to prevent spam, import is triggered by sending a fee with the specific payment ID below to import.mymonero.com."
//				const view = commonComponents_tooltips.New_TooltipSpawningButtonView(tooltipText, self.context)
//				self.informationalHeaderLayer.appendChild(layer) // we can append straight to layer as we don't ever change its innerHTML after this
			}
			do {
				self.toAddress_inputView.text = payment_address
				self.toAddress_labelAccessory_copyButton.set(text: payment_address)
				//
				self.paymentID_inputView.text = payment_id
				self.paymentID_labelAccessory_copyButton.set(text: payment_id)
				//
				var amountStr = formatted_importFee
				if amountStr.contains(".") == false {
					amountStr += ".00"
				}
				amountStr = "0" + amountStr
				self.amount_fieldset.inputField.text = amountStr
			}
			do {
//				// const command = `transfer 3 import.mymonero.com ${import_fee__JSBigInt} ${payment_id}`
//				const tooltipText = "For convenience you may send the fee from MyMonero here, or the official CLI or GUI tools, or any other Monero wallet.<br/><br/>Please be sure to use the exact payment ID below, so the server knows which wallet to import."
//				const view = commonComponents_tooltips.New_TooltipSpawningButtonView(tooltipText, self.context)
//				const layer = view.layer
//				self.walletSelectLabelLayer.appendChild(layer) // we can append straight to layer as we don't ever change its innerHTML after this
			}
			//
			self.view.setNeedsLayout()
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
						"Sending \(self.importRequestInfoAndStatus_receivedResult!.import_fee.humanReadableString) XMR…",
						comment: ""
					),
					wantsXButton: false
				)
				self.disableForm()
				self.set_isFormSubmittable_needsUpdate() // update submittability
			}
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			let result = self.importRequestInfoAndStatus_receivedResult!
			let parameters = ImportTransactionsModal.SubmissionController.Parameters(
				fromWallet: fromWallet,
				infoRequestParsingResult: result,
				preSuccess_terminal_validationMessage_fn:
				{ [unowned self] (localized_errStr) in
					self.reEnableForm() // important
					self.setValidationMessage(localized_errStr)
				})
				{ [unowned self] in // success
					self.submissionController = nil // free
					self.set(
						validationMessage: NSLocalizedString("Sent!", comment: ""),
						wantsXButton: false
					)
					DispatchQueue.main.asyncAfter( 
						deadline: .now() + 1.0, // for effect
						execute:
						{ [unowned self] in // Now dismiss
							self.navigationController?.dismiss(animated: true, completion: nil)
						}
					)
					DispatchQueue.main.async
					{ // and fire off a request to have the wallet get the latest (real) tx records
						fromWallet.hostPollingController!._fetch_addressTransactions() // TODO: maybe fix up the API for this
					}					
				}
			let controller = ImportTransactionsModal.SubmissionController(parameters: parameters)
			self.submissionController = controller
			controller.handle()
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
				let w = textField_w
				self.informationalLabel.frame = CGRect(
					x: CGFloat.form_input_margin_x,
					y: ceil(top_yOffset),
					width: w,
					height: 0
				).integral
				self.informationalLabel.sizeToFit()
				self.informationalLabel.frame = CGRect(
					x: self.informationalLabel.frame.origin.x,
					y: self.informationalLabel.frame.origin.y,
					width: w, // now return to original width to get centering (as the text run may have been too short to take up the whole h space)
					height: self.informationalLabel.frame.size.height
				).integral
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
		//
		// Delegation
		override func viewDidAppear(_ animated: Bool)
		{
			super.viewDidAppear(animated)
			self.doDataRequest_ifNecessary()
		}
	}
}
