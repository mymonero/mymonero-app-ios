//
//  ExchangeShowOrderStatusFormViewController.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/11/03.
//  Copyright © 2020 MyMonero. All rights reserved.
//

import Alamofire
import UIKit
import SwiftyJSON

//extension Date {
//	init(_ dateString:String) {
//		// YYYY-MM-DD
//		let dateStringFormatter = DateFormatter()
//		dateStringFormatter.dateFormat = "yyyy-MM-dd"
//		dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
//		let date = dateStringFormatter.date(from: dateString)!
//		self.init(timeInterval:0, since:date)
//	}
//}

class ExchangeShowOrderStatusFormViewController: UICommonComponents.FormViewController
{
	//
	// Properties - Set-up
	var toWallet_label: UICommonComponents.Form.FieldLabel!
	var toWallet_inputView: UICommonComponents.WalletPickerButtonFieldView!
	//
	var amount_label: UICommonComponents.Form.FieldLabel!
	var amount_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var amount_fieldset: UICommonComponents.Form.Amounts.InputFieldsetView!
	//
	var memo_label: UICommonComponents.Form.FieldLabel!
	var memo_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var memo_inputView: UICommonComponents.FormInputField!
	//
	var requestFrom_label: UICommonComponents.Form.FieldLabel!
	var requestFrom_accessoryLabel: UICommonComponents.Form.FieldLabelAccessoryLabel!
	var requestFrom_inputView: UICommonComponents.Form.ContactAndAddressPickerView!
	var isWaitingOnFieldBeginEditingScrollTo_requestFrom = false // a bit janky
	//
	var createNewContact_buttonView: UICommonComponents.LinkButtonView!
	var addPaymentID_buttonView: UICommonComponents.LinkButtonView!
	//
	var manualPaymentID_label: UICommonComponents.Form.FieldLabel!
	var generatePaymentID_linkButtonView: UICommonComponents.LinkButtonView!
	var manualPaymentID_inputView: UICommonComponents.FormInputField!
	//
	
	var selectedWallet: Wallet!
	var sendTransaction_button: UIButton!
	var orderDetails: [String:Any]
	var orderId: String?
	

	var expiryDate: Date?
	var uuid_label: UICommonComponents.Form.FieldLabel!
	var uuid_inputView: UICommonComponents.FormInputField!
	var disclaimer_label: UICommonComponents.Form.FieldLabel!
	var timeRemaining_label: UICommonComponents.Form.FieldLabel!
	var timeRemaining_inputView: UICommonComponents.FormInputField!
	var remainingCurrencyPayable_label: UICommonComponents.Form.FieldLabel!
	var remainingCurrencyPayable_inputView: UICommonComponents.FormInputField!
	var currencyValuePayout_label: UICommonComponents.Form.FieldLabel!
	var currencyValuePayout_inputView: UICommonComponents.FormInputField!
	var orderStatus_label: UICommonComponents.Form.FieldLabel!
	var orderStatus_inputView: UICommonComponents.FormInputField!
	var confirmSendFunds_buttonView: UICommonComponents.ActionButton!
	var btcAddress: String!
	weak var orderUpdateTimer: Timer?
	weak var timeRemainingTimer: Timer?
	var orderCalendar: Calendar
	private let apiUrl = "https://api.mymonero.com:8443/cx/"
	//private let apiUrl = "https://stagenet-api.mymonero.rtfm.net/cx/"

	func updateOrderStatus(orderId: String!, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
		dispatchGetOrderUpdate(orderId: orderId, completion: completionHandler)
	}
	
	func dispatchGetOrderUpdate(orderId: String!, completion: @escaping (Result<[String: Any]>) -> Void) {
		debugPrint("Check the order id -- \(orderId)")
		let params: [String: String] = [
			"order_id": orderId
		]
		debugPrint(params)
		debugPrint("Fired order status query")
		let method = "order_status"
		let apiEndpoint = apiUrl + method
		Alamofire.request(apiEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default)
			.responseJSON {
				response in
				// add switch response.result here. Check for cases .success, .failure, default
				debugPrint(response)
				switch response.result {
				case .success(let value as [String: Any]):
					completion(.success(value))

				case .failure(let error):
					completion(.failure(error))

				default:
					fatalError("received non-dictionary JSON response")
				}
			}
	}
	
	func getOrderStatus(orderId: String!, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
		dispatchOrderStatusQuery(orderId: orderId, completion: completionHandler)
	}
	
	func dispatchOrderStatusQuery(orderId: String!, completion: @escaping (Result<[String: Any]>) -> Void) {
		debugPrint("Check the order id -- \(orderId)")
		let params: [String: String] = [
			"order_id": orderId
		]
		debugPrint(params)
		debugPrint("Fired order status update query")
		let method = "order_status"
		let apiEndpoint = apiUrl + method
		Alamofire.request(apiEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default)
			.responseJSON {
				response in
				// add switch response.result here. Check for cases .success, .failure, default
				debugPrint(response)
				switch response.result {
				case .success(let value as [String: Any]):
					completion(.success(value))

				case .failure(let error):
					completion(.failure(error))

				default:
					fatalError("received non-dictionary JSON response")
				}
			}
	}
	
	@objc func handleRemainingTimeUpdateTimer() {
			let now = Date()
			
			if (now > self.expiryDate!) {
				debugPrint("Time epxired")
				self.stopRemainingTimeTimer()
			}
			
			let difference = self.orderCalendar.dateComponents([.hour, .minute, .second], from: Date(), to: self.expiryDate!)
			
			if (difference.hour! > 0) {
				self.timeRemaining_inputView.text = "\(difference.hour!) hour(s) \(difference.minute!) min \(difference.second) seconds"
			} else	if (difference.minute! > 0) {
					self.timeRemaining_inputView.text = "\(difference.minute!) min \(difference.second!) seconds"
			} else {
				self.timeRemaining_inputView.text = "\(difference.second!) seconds"
			}
			debugPrint(difference)
	}
	
	@objc func handleOrderUpdateTimer() {
		self.updateOrderStatus(orderId: self.orderId) {
			result in
			debugPrint("Order update handler")
			debugPrint(result)
			switch result {
				case .failure (let error):
					debugPrint(error)
				case .success(let value):
					debugPrint(value["in_currency"])
					// We should only really care about the order state, but we'll update all values here in case the first order status query fails
					self.orderStatus_inputView.text = value["status"] as? String
					self.uuid_inputView.text = value["provider_order_id"] as? String
					self.currencyValuePayout_inputView.text = value["out_amount"] as? String
					self.remainingCurrencyPayable_inputView.text = value["in_amount"] as? String
					// Code here is to check if the state is concluded, and if so, terminate the timers
					// if the order is completed successfully, it'll return PAID || PAID_UNCONFIRMED -- we only want to terminate on PAID
					// if the order has timed out, it'll return TIMED_OUT
					if (self.orderStatus_inputView.text == "PAID" || self.orderStatus_inputView.text == "TIMED_OUT") {
						self.stopRemainingTimeTimer()
						self.stopOrderUpdateTimer()
					}
					
				default:
					debugPrint("received non-dictionary JSON response")
			}
		}
	}
	
	@objc func startRemainingTimeTimer()
	{
		timeRemainingTimer?.invalidate()
		timeRemainingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleRemainingTimeUpdateTimer), userInfo: nil, repeats: true)
	}

	@objc func stopRemainingTimeTimer() {
		timeRemainingTimer?.invalidate()
	}
	
	@objc func startOrderUpdateTimer()
	{
		orderUpdateTimer?.invalidate()
		orderUpdateTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(handleOrderUpdateTimer), userInfo: nil, repeats: true)
	}
	
	@objc func stopOrderUpdateTimer() {
		orderUpdateTimer?.invalidate()
	}
	
	deinit {
		stopRemainingTimeTimer()
		stopOrderUpdateTimer()
	}
	//
	//
	// Lifecycle - Init
	required init(
		selectedWallet: Wallet!,
		orderDetails: [String:Any],
		orderId: String
	) {

		self.orderCalendar = Calendar.current
		debugPrint("Hello from order details")
		debugPrint(orderDetails)

		self.selectedWallet = selectedWallet
		self.orderDetails = orderDetails
		self.orderId = orderId

		debugPrint("Invoking getOrderStatus with order_id: \(orderId)")
		super.init()
		// Dispatch AF call to retrieve order status
		// getOrderStatus returns a closure
		//self.getOrderStatus(orderId: self.orderDetails.result.order_id) {
		self.getOrderStatus(orderId: orderId) {
			result in
			debugPrint("Right button clicked to instantiate order -- closure")
			debugPrint(result)
			switch result {
				case .failure (let error):
					debugPrint(error)
					// There's a chance we may not successfully retrieve the order details, in which case they'll get updated by the order status updater
				case .success(let value):
					self.uuid_inputView.text = value["provider_order_id"] as? String
					self.orderStatus_inputView.text = value["status"] as? String
					self.currencyValuePayout_inputView.text = value["out_amount"] as? String
					self.remainingCurrencyPayable_inputView.text = value["in_amount"] as? String
					
					var expiryStr: String?
					expiryStr = value["expires_at"] as? String

					self.startOrderUpdateTimer()
					//self.expiryDate = Date(value["expires_at"] as! String)
					// Set up timer
					var dateFormatter = ISO8601DateFormatter()
					
					if (!(expiryStr == nil)) {
						self.expiryDate = dateFormatter.date(from: expiryStr!)
						
						// if not nil, we have a valid date, and we can go ahead and

						
						let calendar = Calendar.current
						let now = Date()
						let difference = calendar.dateComponents([.hour, .minute, .second], from: Date(), to: self.expiryDate!)
						
						if self.expiryDate != nil {
							self.startRemainingTimeTimer()						}
						debugPrint(difference)
					} else {
						debugPrint("Error with server response")
					}
					
					//2020-11-05T10:46:15Z
					// we need an error output area
					
			}
		}
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	override func setup_views()
	{
		super.setup_views()
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("RECEIVE MONasdasERO AT", comment: "")
			)
			self.toWallet_label = view
			self.scrollView.addSubview(view)
		}
//		do {
//			let view = UICommonComponents.ActionButton()
//			view.setTitle("Test send button", for: UIControl.State)
//			self.sendTransaction_button = view
//			self.scrollView.addSubview(view)
//		}
//		do {
//			let view = UICommonComponents.Form.FieldLabel(
//				title: NSLocalizedString("RECEIVE MONERO AT", comment: "")
//			)
//			self.toWallet_label = view
//			self.scrollView.addSubview(view)
//		}
		do {
			let view = UICommonComponents.WalletPickerButtonFieldView(selectedWallet: nil)
			self.toWallet_inputView = view
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
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			self.amount_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.Amounts.InputFieldsetView(
				effectiveAmountLabelBehavior: .yieldingRawUserInputParsedDouble // different from SendFunds
			)
			// KB: Remove this and accompanying code
			view.didUpdateValueAvailability_fn =
			{ [weak self] in
				// this will be called when the ccyConversion rate changes and when the selected currency changes
				guard let thisSelf = self else {
					return
				}
				thisSelf.set_isFormSubmittable_needsUpdate() // wait for ccyConversion rate to come in from what ever is supplying it
				// TODO: do we need to update anything else here?
			}
			let inputField = view.inputField
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .next
			self.amount_fieldset = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("MEMO", comment: "")
			)
			self.memo_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			self.memo_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("Note about the transaction", comment: "")
			)
			let inputField = view
			inputField.autocorrectionType = AppProcess.isBeingRunByUIAutomation ? .no : .default // disabled under UI automation b/c it interferes with .typeText and the known fallback is too fragile
			inputField.autocapitalizationType = .sentences
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .next
			self.memo_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("REQUEST MONERO FROM", comment: "")
			)
			self.requestFrom_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabelAccessoryLabel(title: NSLocalizedString("optional", comment: ""))
			self.requestFrom_accessoryLabel = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.ContactAndAddressPickerView(
				parentScrollView: self.scrollView
			)
			// TODO: initial contact selection? (from spawn)
			view.textFieldDidBeginEditing_fn =
			{ [unowned self] (textField) in
				self.view.setNeedsLayout() // to be certain we get the updated bottom padding
				//
				self.aField_didBeginEditing(textField, butSuppressScroll: true) // suppress scroll and call manually
				// ^- this does not actually do anything at present, given suppressed scroll
				self.isWaitingOnFieldBeginEditingScrollTo_requestFrom = true // sort of janky
				DispatchQueue.main.asyncAfter(
					deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
				) // slightly janky to use delay/duration, we need to wait (properly/considerably) for any layout changes that will occur here
				{ [unowned self] in
					self.isWaitingOnFieldBeginEditingScrollTo_requestFrom = false // unset
					if view.inputField.isFirstResponder { // jic
						self.scrollToVisible_requestFrom()
					}
				}
			}
			view.didUpdateHeight_fn =
			{ [unowned self] in
				self.view.setNeedsLayout() // to get following subviews' layouts to update
				//
				// scroll to field in case, e.g., results table updated
				DispatchQueue.main.asyncAfter(
					deadline: .now() + 0.1
				) { [unowned self] in
					if self.isWaitingOnFieldBeginEditingScrollTo_requestFrom == true {
						return // semi-janky -- but is used to prevent potential double scroll oddness
					}
					if view.inputField.isFirstResponder {
						self.scrollToVisible_requestFrom()
					}
				}
			}
			view.textFieldDidEndEditing_fn =
			{ (textField) in
				// nothing to do in this case
			}
			view.didPickContact_fn =
			{ [unowned self] (contact, doesNeedToResolveItsOAAddress) in
				do { // configurations regardless
					self.createNewContact_buttonView.isHidden = true
				}
				if doesNeedToResolveItsOAAddress == true { // so we still need to wait and check to see if they have a payment ID
					self.addPaymentID_buttonView.isHidden = true // hide if showing
					self.hideAndClear_manualPaymentIDField() // at least clear; hide for now
					//
					// contact picker will show its own resolving indicator while we look up the paymentID again
					self.set_isFormSubmittable_needsUpdate() // this will involve a check to whether the contact picker is resolving
					//
					self.clearValidationMessage() // assuming it's okay to do this here - and need to since the coming callback can set the validation msg
					//
					return
				}
				// does NOT need to resolve an OA address; handle contact's non-OA payment id - if we already have one
				if let paymentID = contact.payment_id {
					self.addPaymentID_buttonView.isHidden = true // hide if showing
					self.show_manualPaymentIDField(withValue: paymentID)
					// NOTE: ^--- This may seem unusual not to show as a 'detected' payment ID
					// here but unlike on the Send page, Requests (I think) must be able to be created
					// with an empty / nil payment ID field even though the user picked a contact.
				} else {
					self.addPaymentID_buttonView.isHidden = false // show if hidden
					self.hideAndClear_manualPaymentIDField() // hide if showing
				}
			}
			view.oaResolve__preSuccess_terminal_validationMessage_fn =
			{ [unowned self] (localizedString) in
				self.setValidationMessage(localizedString)
				self.set_isFormSubmittable_needsUpdate() // as it will check whether we are resolving
			}
			view.oaResolve__success_fn =
			{ [unowned self] (resolved_xmr_address, payment_id, tx_description) in
				self.set_isFormSubmittable_needsUpdate() // will check if picker is resolving
				do { // memo field
					self.memo_inputView.text = tx_description ?? "" // even if one was already entered; this is tbh an approximation of the behavior we want; ideally we'd try to detect and track whether the user intended to use/type their own custom memo – but that is surprisingly involved to do well enough! at least for now.
				}
				do { // there is no need to tell the contact to update its address and payment ID here as it will be observing the emitted event from this very request to .Resolve
					if payment_id != "" {
						self.addPaymentID_buttonView.isHidden = true // hide if showing
						self.show_manualPaymentIDField(withValue: payment_id)
					} else {
						// we already hid it above… but just in case
						self.addPaymentID_buttonView.isHidden = false // show if showing
						self.hideAndClear_manualPaymentIDField()
					}
				}
			}
			view.didClearPickedContact_fn =
			{ [unowned self] (preExistingContact) in
				self.clearValidationMessage() // in case there was an OA addr resolve network err sitting on the screen
				//
				self.set_isFormSubmittable_needsUpdate() // as it will look at resolving
				//
				self.addPaymentID_buttonView.isHidden = false // show if hidden
				self.hideAndClear_manualPaymentIDField() // if showing
				//
				if preExistingContact.hasOpenAliasAddress {
					self.memo_inputView.text = "" // we're doing this here to avoid stale state and because implementing proper detection of which memo the user intends to leave in there for this particular request is quite complicated. see note in _didPickContact… but hopefully checking having /come from/ an OA contact is good enough
				}
				self.createNewContact_buttonView.isHidden = false // show if hidden
			}
			let inputField = view.inputField
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			self.requestFrom_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("+ CREATE NEW CONTACT", comment: ""))
			view.addTarget(self, action: #selector(createNewContact_tapped), for: .touchUpInside)
			self.createNewContact_buttonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("+ ADD PAYMENT ID", comment: ""))
			view.addTarget(self, action: #selector(addPaymentID_tapped), for: .touchUpInside)
			self.addPaymentID_buttonView = view
			self.scrollView.addSubview(view)
		}
		
		do {
			let view = UICommonComponents.Form.FieldLabel(
				title: NSLocalizedString("ENTER PAYMENT ID OR", comment: "")
			)
			view.isHidden = true // initially
			self.manualPaymentID_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("GENERATE ONE", comment: ""))
			view.addTarget(self, action: #selector(tapped_generatePaymentID), for: .touchUpInside)
			view.isHidden = true // initially
			self.generatePaymentID_linkButtonView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(
				placeholder: NSLocalizedString("A specific payment ID", comment: "")
			)
			view.isHidden = true // initially
			let inputField = view
			inputField.autocorrectionType = .no
			inputField.autocapitalizationType = .none
			inputField.delegate = self
			inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
			inputField.returnKeyType = .go
			self.manualPaymentID_inputView = view
			self.scrollView.addSubview(view)
		}
		//
		//
		//
		// Declare exchange form view fields
		do {
			let disclaimer = """
			Please note that MyMonero cannot provide support for any exchanges. For all issues, please contact XMR.to with your transaction ID, as they will be able to assist.
			"""
			let view = UICommonComponents.Form.FieldLabel(title: disclaimer)
			self.disclaimer_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "XMR.TO transaction id")
			self.uuid_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("XMR.TO transaction id", comment: ""))
			self.uuid_inputView = view
			self.uuid_inputView.isEnabled = false
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "Time Remaining")
			self.timeRemaining_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("Time Remaining", comment: ""))
			self.timeRemaining_inputView = view
			self.timeRemaining_inputView.isEnabled = false
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "XMR payable")
			self.remainingCurrencyPayable_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("XMR payable", comment: ""))
			self.remainingCurrencyPayable_inputView = view
			self.remainingCurrencyPayable_inputView.isEnabled = false
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "BTC to be received")
			self.currencyValuePayout_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("BTC to be received", comment: ""))
			self.currencyValuePayout_inputView = view
			self.currencyValuePayout_inputView.isEnabled = false
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "Order Status")
			self.orderStatus_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("Order Status", comment: ""))
			self.orderStatus_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
//			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("Send Funds", comment: ""))
//			view.addTarget(self, action: #selector(tapped_sendFunds), for: .touchUpInside)
//			self.confirmSendFunds_buttonView = view
//			self.scrollView.addSubview(view)
			let view = UICommonComponents.ActionButton(pushButtonType: .action, isLeftOfTwoButtons: false)
			view.addTarget(self, action: #selector(tapped_sendFunds), for: .touchUpInside)
			view.setTitle(NSLocalizedString("Send Funds", comment: ""), for: .normal)
			view.accessibilityIdentifier = "button.sendFunds"
			self.confirmSendFunds_buttonView = view
			self.scrollView.addSubview(view)
		}
		//
	}
	override func setup_navigation()
	{
		super.setup_navigation()
//		self.navigationItem.title = NSLocalizedString("New Request", comment: "")
//		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
//			type: .save,
//			target: self,
//			action: #selector(tapped_rightBarButtonItem)
//		)
		self.navigationItem.title = NSLocalizedString("Send Monero", comment: "")
//		self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
//			type: .payExchangeOrder,
//			target: self,
//			action: #selector(tapped_rightBarButtonItem)
//		)
//		self.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
//			type: .back,
//			target: self,
//			action: #selector(tapped_barButtonItem_cancel)
//		)
//		super.navigationItem.leftBarButtonItem = UICommonComponents.NavigationBarButtonItem(
//			type: .back,
//			target: self,
//			action: #selector(tapped_barButtonItem_cancel)
//		)
		self.navigationController?.parent?.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
			type: .payExchangeOrder,
			target: self,
			action: #selector(tapped_rightBarButtonItem)
		)
	}
	//
	// Accessors - Overrides
	override func new_isFormSubmittable() -> Bool
	{
		if self.formSubmissionController != nil {
			return false
		}
		if self.requestFrom_inputView.isResolving {
			return false
		}
		// NOTE: here we need to allow empty amounts
		let hasInputButDoubleFormatIsNotSubmittable = self.amount_fieldset.inputField.hasInputButDoubleFormatIsNotSubmittable
		if hasInputButDoubleFormatIsNotSubmittable {
			return false // for ex if they just put in "."
		}
		return true
	}
	//
	// Accessors - Overrides
	override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
	{
		switch inputView {
			case self.toWallet_inputView.picker_inputField:
				return self.amount_fieldset.inputField
			case self.amount_fieldset.inputField:
				return self.memo_inputView
			case self.memo_inputView:
				if self.requestFrom_inputView.inputField.isHidden == false {
					return self.requestFrom_inputView.inputField
				} else if self.manualPaymentID_inputView.isHidden == false {
					return self.manualPaymentID_inputView
				}
				return nil
			case self.requestFrom_inputView.inputField:
				if self.manualPaymentID_inputView.isHidden == false {
					return manualPaymentID_inputView
				}
				return nil
			case self.manualPaymentID_inputView:
				return nil
			default:
				assert(false, "Unexpected")
				return nil
		}
	}
	override func new_wantsBGTapRecognizerToReceive_tapped(onView view: UIView) -> Bool
	{
		if view.isAnyAncestor(self.requestFrom_inputView) {
			// this is to prevent taps on the searchResults tableView from dismissing the input (which btw makes selection of search results rows impossible)
			// but it's ok if this is the inputField itself
			return false
		}
		return super.new_wantsBGTapRecognizerToReceive_tapped(onView: view)
	}
	//
	// Accessors
	var sanitizedInputValue__toWallet: Wallet {
		return self.toWallet_inputView.selectedWallet! // we are never expecting this modal to be visible when no wallets exist, so a crash is/ought to be ok
	}
	var sanitizedInputValue__selectedContact: Contact? {
		return self.requestFrom_inputView.selectedContact
	}
	var sanitizedInputValue__paymentID: MoneroPaymentID? {
		if self.manualPaymentID_inputView.text != nil && self.manualPaymentID_inputView!.isHidden != true {
			let stripped_paymentID = self.manualPaymentID_inputView!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
			if stripped_paymentID != "" {
				return stripped_paymentID
			}
		}
		return nil
	}
	//
	// Imperatives - Field visibility/configuration
	func set_manualPaymentIDField(isHidden: Bool)
	{
		self.manualPaymentID_label.isHidden = isHidden
		self.manualPaymentID_inputView.isHidden = isHidden
		self.generatePaymentID_linkButtonView.isHidden = isHidden
		self.view.setNeedsLayout()
	}
	func show_manualPaymentIDField(withValue paymentID: String?)
	{
		self.manualPaymentID_inputView.text = paymentID ?? "" // nil to empty field
		self.set_manualPaymentIDField(isHidden: false)
	}
	func hideAndClear_manualPaymentIDField()
	{
		self.set_manualPaymentIDField(isHidden: true)
		self.manualPaymentID_inputView.text = ""
	}
	//
	// Imperatives - Contact picker, contact picking
	func scrollToVisible_requestFrom()
	{
		self.scrollInputViewToVisible(self.requestFrom_inputView)
	}
	public func reconfigureFormAtRuntime_havingElsewhereSelected(
		requestFromContact contact: Contact?,
		receiveToWallet wallet: Wallet?
	) {
		self.amount_fieldset.clear() // figure that since this method is called when user is trying to initiate a new request, we should clear the amount
		//
		if contact != nil {
			self.requestFrom_inputView.pick(contact: contact!)
		} else {
			self.requestFrom_inputView.unpickSelectedContact_andRedisplayInputField()
		}
		//
		if wallet != nil {
			self.toWallet_inputView.set(selectedWallet: wallet!)
		}
	}
	//
	// Runtime - Imperatives - Overrides
	override func disableForm()
	{
		super.disableForm()
		//
		self.scrollView.isScrollEnabled = false
		//
		self.confirmSendFunds_buttonView.isEnabled = false
//		self.toWallet_inputView.set(isEnabled: false)
//
//		self.amount_fieldset.inputField.isEnabled = false
//		self.amount_fieldset.currencyPickerButton.isEnabled = false
//
//		self.memo_inputView.isEnabled = false
//		self.requestFrom_inputView.inputField.isEnabled = false
//		if let pillView = self.requestFrom_inputView.selectedContactPillView {
//			pillView.xButton.isEnabled = true
//		}
//		self.manualPaymentID_inputView.isEnabled = false
//		self.generatePaymentID_linkButtonView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.confirmSendFunds_buttonView.isEnabled = true
//		self.toWallet_inputView.set(isEnabled: true)
//
//		self.amount_fieldset.inputField.isEnabled = true
//		self.amount_fieldset.currencyPickerButton.isEnabled = true
//
//		self.memo_inputView.isEnabled = true
//		self.requestFrom_inputView.inputField.isEnabled = true
//		if let pillView = self.requestFrom_inputView.selectedContactPillView {
//			pillView.xButton.isEnabled = true
//		}
//		self.manualPaymentID_inputView.isEnabled = true
//		self.generatePaymentID_linkButtonView.isEnabled = true
	}
	var formSubmissionController: ExchangeSendFundsForm.SubmissionController? // TODO: maybe standardize into FormViewController
	
	override func _tryToSubmitForm()
	{
		self.disableForm() // optimistic
		/* Old Submit form validation logic */
		//
//		let selectedContact = self.sendTo_inputView.selectedContact
//		let enteredAddressValue = self.sendTo_inputView.inputField.text
//		//
//		let resolvedAddress_fieldIsVisible = self.sendTo_inputView.resolvedXMRAddr_inputView != nil && self.sendTo_inputView.resolvedXMRAddr_inputView?.isHidden == false
//		let resolvedAddress = resolvedAddress_fieldIsVisible ? self.sendTo_inputView.resolvedXMRAddr_inputView?.textView.text : nil
//		//
//		let manuallyEnteredPaymentID_fieldIsVisible = self.manualPaymentID_inputView.isHidden == false
//		let manuallyEnteredPaymentID = manuallyEnteredPaymentID_fieldIsVisible ? self.manualPaymentID_inputView.text : nil
//		//
//		let resolvedPaymentID_fieldIsVisible = self.sendTo_inputView.resolvedPaymentID_inputView != nil && self.sendTo_inputView.resolvedPaymentID_inputView?.isHidden == false
//		let resolvedPaymentID = resolvedPaymentID_fieldIsVisible ? self.sendTo_inputView.resolvedPaymentID_inputView?.textView.text ?? "" : nil
//		//
//		let priority = self.selected_priority
//		//
		// End of Submit form validation logic
		
		//
		var enteredAddressValue: MoneroAddress? = self.orderDetails["in_address"] as? String
		var raw_amount_string: String? = self.orderDetails["in_amount"] as? String
		var resolvedAddress: MoneroAddress?
		var manuallyEnteredPaymentID: MoneroPaymentID?
		var resolvedPaymentID: MoneroPaymentID?
		var hasPickedAContent: Bool = false
		//
		var resolvedAddress_fieldIsVisible: Bool = false
		var manuallyEnteredPaymentID_fieldIsVisible: Bool = false
		var resolvedPaymentID_fieldIsVisible: Bool = false
		var contactPaymentID: MoneroPaymentID?
		//		var cached_OAResolved_address: String?
		//		var contact_hasOpenAliasAddress: Bool = false
		//		var contact_address: String?
		//		var raw_amount_string: String = "0.000001"
		var isSweeping: Bool = false
		var priority: MoneroTransferSimplifiedPriority = .low
		//		var preSuccess_nonTerminal_validationMessageUpdate_fn: (_ localizedString: String) -> Void
		//		var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		//		var preSuccess_passedValidation_willBeginSending: () -> Void
		//		var canceled_fn: () -> Void
		//		var success_fn: (
		//			_ mockedTransaction: MoneroHistoricalTransactionRecord,
		//			_ sentTo_address: MoneroAddress, // this may differ from enteredAddress.. e.g. std addr + short pid -> int addr
		//			_ isXMRAddressIntegrated: Bool, // regarding sentTo_address
		//			_ integratedAddressPIDForDisplay_orNil: MoneroPaymentID?
		//		) -> Void
		////		var validation_status_fn: Typehere = validation_status_fn "",
		////		var cancelled_fn: Typehere = cancelled_fn "",
		////		var handle_response_fn: Typehere = handle_response_fn ""
		//
		var fromWallet = self.selectedWallet
		var selectedContact: Contact?

		var amount_submittableDouble = Double(raw_amount_string!)
		//amount_submittableDouble = raw_amount_string.tofl
		
		// TODO: KB: Remove this testing code
		amount_submittableDouble = 0.000001
		enteredAddressValue = "45am3uVv3gNGUWmMzafgcrAbuw8FmLmtDhaaNycit7XgUDMBAcuvin6U2iKohrjd6q2DLUEzq5LLabkuDZFgNrgC9i3H4Tm"
		// END OF TEST CODE
		let parameters = ExchangeSendFundsForm.SubmissionController.Parameters(
			fromWallet: self.selectedWallet,
			amount_submittableDouble: amount_submittableDouble,
			isSweeping: isSweeping,
			priority: priority,
			//
			selectedContact: selectedContact,
			enteredAddressValue: enteredAddressValue,
			//
			resolvedAddress: resolvedAddress,
			resolvedAddress_fieldIsVisible: resolvedAddress_fieldIsVisible,
			//
			manuallyEnteredPaymentID: manuallyEnteredPaymentID,
			manuallyEnteredPaymentID_fieldIsVisible: manuallyEnteredPaymentID_fieldIsVisible,
			resolvedPaymentID: resolvedPaymentID,
			resolvedPaymentID_fieldIsVisible: resolvedPaymentID_fieldIsVisible,
			//
			preSuccess_nonTerminal_validationMessageUpdate_fn:
			{ [unowned self] (localizedString) in
				self.set(
					validationMessage: localizedString,
					wantsXButton: false // false b/c it's nonTerminal
				)
			},
			preSuccess_terminal_validationMessage_fn:
			{ [unowned self] (localizedString) in
				self.set(
					validationMessage: localizedString,
					wantsXButton: true // true because it's terminal
				)
				self.formSubmissionController = nil // must free as this is a terminal callback
				self.set_isFormSubmittable_needsUpdate()
				self.reEnableForm() // b/c we disabled it
			},
			preSuccess_passedValidation_willBeginSending:
			{
			},
			canceled_fn:
			{ [weak self] in
				guard let thisSelf = self else {
					return
				}
				thisSelf.clearValidationMessage() // un-set "Sending... "
				//
				thisSelf.formSubmissionController = nil // must free as this is a terminal callback
				thisSelf.set_isFormSubmittable_needsUpdate()
				thisSelf.reEnableForm() // b/c we disabled it
			},
			success_fn:
			{ [unowned self] (
				mockedTransaction,
				sentTo_address,
				isXMRAddressIntegrated,
				integratedAddressPIDForDisplay_orNil
			) in
				self.formSubmissionController = nil
				
				// must free as this is a terminal callback
				self.scrollView.isScrollEnabled = true
				self.set(
					validationMessage: NSLocalizedString("Your Monero is on its way.", comment: ""),
					wantsXButton: true // true because it's terminal
				)
				

				
//				do {
//					let viewController = TransactionDetails.ViewController(
//						transaction: mockedTransaction,
//						inWallet: fromWallet!
//					)
//					self.navigationController!.pushViewController(
//						viewController,
//						animated: true
//					)
//				}
//				do { // and after a delay, present AddContactFromSendTabView
//					if selectedContact == nil { // so they went with a text input address
//						DispatchQueue.main.asyncAfter(
//							deadline: .now() + 0.75 + 0.3, // after the navigation transition just above has taken place, and given a little delay for user to get their bearings
//							execute:
//							{ [unowned self] in
//								let parameters = AddContactFromSendFundsTabFormViewController.InitializationParameters(
//									enteredAddressValue: enteredAddressValue!,
//									integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil, // NOTE: this will be non-nil if a short pid is supplied with a standard address - rather than an integrated addr alone being used
//									resolvedAddress: resolvedAddress_fieldIsVisible ? resolvedAddress : nil,
//									sentWith_paymentID: mockedTransaction.paymentId // will not be nil for integrated enteredAddress
//								)
//								let viewController = AddContactFromSendFundsTabFormViewController(
//									parameters: parameters
//								)
//								let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
//								navigationController.modalPresentationStyle = .formSheet
//								self.navigationController!.present(navigationController, animated: true, completion: nil)
//							}
//						)
//					}
//				}
//				do { // finally, clean up form
//					DispatchQueue.main.asyncAfter(
//						deadline: .now() + 0.5, // after the navigation transition just above has taken place
//						execute:
//						{ [unowned self] in
//							self._clearForm()
//							// and lastly, importantly, re-enable everything
//							self.reEnableForm()
//						}
//					)
//				}
			}
		)
		
		
		// TODO: KB: remove this debug code
//		debugPrint("Exitting in ESOSFVC -- finalising proper order parameters")
//		debugPrint(parameters)
//		return
		let controller = ExchangeSendFundsForm.SubmissionController(parameters: parameters)
		self.formSubmissionController = controller
		do {
			self.disableForm()
			self.set_isFormSubmittable_needsUpdate() // update submittability; after setting self.submissionController
		}
		controller.handle()
	}
	
	func _clearForm() {
		debugPrint("Clear form")
	}
	//
	// Delegation - Form submission success
	func _didSave(instance: FundsRequest)
	{
		let viewController = FundsRequestDetailsViewController(fundsRequest: instance)
		let rootViewController = WindowController.rootViewController!
		let fundsRequestsTabNavigationController = rootViewController.tabBarViewController.fundsRequestsTabViewController
		fundsRequestsTabNavigationController.pushViewController(viewController, animated: false) // NOT animated
		DispatchQueue.main.async // on next tick to make sure push view finished
		{ [unowned self] in
			self.navigationController!.dismiss(animated: true, completion: nil)
		}
	}
	//
	// Delegation - View
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		//
		let subviewLayoutInsets = self.new_subviewLayoutInsets
		let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
		//
		let offscreen_x = CGPoint(x: -5000, y: 0)
		let label_x = self.new__label_x
		let input_x = self.new__input_x
		let textField_w = self.new__textField_w // already has customInsets subtracted
		let fullWidth_label_w = self.new__fieldLabel_w // already has customInsets subtracted
		/*
		do {
			self.toWallet_label.frame = CGRect(
				x: label_x,
				y: top_yOffset,
				width: fullWidth_label_w,
				height: self.toWallet_label.frame.size.height
			).integral
			self.toWallet_inputView.frame = CGRect(
				x: input_x,
				y: self.toWallet_label.frame.origin.y + self.toWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: type(of: self.toWallet_inputView).fixedHeight
			).integral
		}
		*/
		
		do {
			
			self.disclaimer_label.frame = CGRect(
				x: label_x,
				y: top_yOffset,
				width: fullWidth_label_w,
				height: self.disclaimer_label.frame.size.height
			).integral
			self.disclaimer_label.numberOfLines = 0
			self.disclaimer_label.lineBreakMode = NSLineBreakMode.byWordWrapping
			self.disclaimer_label.sizeToFit()
		}
		do {
			self.uuid_label.frame = CGRect(
				x: label_x,
				y: self.disclaimer_label.frame.origin.y + self.disclaimer_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: fullWidth_label_w,
				height: self.uuid_label.frame.size.height
			).integral
			
		}
		do {
			
			self.uuid_inputView.frame = CGRect(
				x: input_x,
				y: self.uuid_label.frame.origin.y + self.uuid_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.uuid_inputView.frame.size.height
			).integral
		}
		do {
			
			self.timeRemaining_label.frame = CGRect(
				x: label_x,
				y: self.uuid_inputView.frame.origin.y + self.uuid_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.timeRemaining_label.frame.size.height
			).integral

		}
		do {
			self.timeRemaining_inputView.frame = CGRect(
				x: input_x,
				y: self.timeRemaining_label.frame.origin.y + self.timeRemaining_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.uuid_inputView.frame.size.height
			).integral
		}
		do {
			
			self.remainingCurrencyPayable_label.frame = CGRect(
				x: label_x,
				y: self.timeRemaining_inputView.frame.origin.y + self.timeRemaining_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.remainingCurrencyPayable_label.frame.size.height
			).integral

		}
		do {
			self.remainingCurrencyPayable_inputView.frame = CGRect(
				x: input_x,
				y: self.remainingCurrencyPayable_label.frame.origin.y + self.remainingCurrencyPayable_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.uuid_inputView.frame.size.height
			).integral
		}
		do {
			
			self.currencyValuePayout_label.frame = CGRect(
				x: label_x,
				y: self.remainingCurrencyPayable_inputView.frame.origin.y
					+ self.remainingCurrencyPayable_inputView.frame.size.height
					+ UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.currencyValuePayout_label.frame.size.height
			).integral

		}
		do {
			self.currencyValuePayout_inputView.frame = CGRect(
				x: input_x,
				y: self.currencyValuePayout_label.frame.origin.y + self.currencyValuePayout_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.currencyValuePayout_inputView.frame.size.height
			).integral
		}
		do {
			
			self.orderStatus_label.frame = CGRect(
				x: label_x,
				y: self.currencyValuePayout_inputView.frame.origin.y
					+ self.currencyValuePayout_inputView.frame.size.height
					+ UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.orderStatus_label.frame.size.height
			).integral

		}
		do {
			self.orderStatus_inputView.frame = CGRect(
				x: input_x,
				y: self.orderStatus_label.frame.origin.y + self.orderStatus_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: self.orderStatus_inputView.frame.size.height
			).integral
		}
		do {
			self.confirmSendFunds_buttonView.frame = CGRect(
				x: input_x,
				y: self.orderStatus_inputView.frame.origin.y + self.orderStatus_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: textField_w,
				height: self.orderStatus_inputView.frame.size.height
			).integral
		}
//		do {
//			self.send
//
//		}

			
		do {
			self.toWallet_label.frame = CGRect(
				x: CGFloat(-5000),
				y: self.disclaimer_label.frame.origin.y + self.toWallet_label.frame.size.height,
				width: fullWidth_label_w,
				height: self.toWallet_label.frame.size.height
			).integral
			self.toWallet_inputView.frame = CGRect(
				x: CGFloat(-5000),
				y: self.disclaimer_label.frame.origin.y + self.disclaimer_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
				width: textField_w,
				height: type(of: self.toWallet_inputView).fixedHeight
			).integral
		}
		do {
			self.amount_label.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: self.toWallet_inputView.frame.origin.y
					+ ceil(self.toWallet_inputView.frame.size.height)/*must ceil or we get a growing height due to .integral + demi-pixel separator thickness!*/
					+ UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.toWallet_label.frame.size.height
				).integral
			self.amount_accessoryLabel.frame = CGRect(
				//x: subviewLayoutInsets.left + CGFloat.form_labelAccessoryLabel_margin_x,
				x: CGFloat(-5000),
				y: self.amount_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.amount_accessoryLabel.frame.size.height
				).integral
			self.amount_fieldset.frame = CGRect(
				//x: input_x,
				x: CGFloat(-5000),
				y: self.amount_label.frame.origin.y + self.amount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w, // full-size width
				height: UICommonComponents.Form.Amounts.InputFieldsetView.h
				).integral
		}
		do {
			self.memo_label.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: self.amount_fieldset.frame.origin.y
					+ self.amount_fieldset.frame.size.height
					+ UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView, // estimated margin
				width: fullWidth_label_w,
				height: self.memo_label.frame.size.height
				).integral
			self.memo_accessoryLabel.frame = CGRect(
				//x: subviewLayoutInsets.left + CGFloat.form_labelAccessoryLabel_margin_x,
				x: CGFloat(-5000),
				y: self.memo_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.memo_accessoryLabel.frame.size.height
				).integral
			self.memo_inputView.frame = CGRect(
				//x: input_x,
				x: CGFloat(-5000),
				y: self.memo_label.frame.origin.y + self.memo_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.memo_inputView.frame.size.height
				).integral
		}
		do {
			self.requestFrom_label.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: self.memo_inputView.frame.origin.y + self.memo_inputView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: fullWidth_label_w,
				height: self.requestFrom_label.frame.size.height
			).integral
			self.requestFrom_accessoryLabel.frame = CGRect(
				x: CGFloat(-5000),
				//x: subviewLayoutInsets.left + CGFloat.form_labelAccessoryLabel_margin_x,
				y: self.requestFrom_label.frame.origin.y,
				width: fullWidth_label_w,
				height: self.requestFrom_accessoryLabel.frame.size.height
			).integral
			self.requestFrom_inputView.frame = CGRect(
				//x: input_x,
				x: CGFloat(-5000),
				y: self.requestFrom_label.frame.origin.y + self.requestFrom_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.requestFrom_inputView.frame.size.height
			).integral
		}
		if self.createNewContact_buttonView.isHidden == false {
			self.createNewContact_buttonView!.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: self.requestFrom_inputView.frame.origin.y + self.requestFrom_inputView.frame.size.height + UICommonComponents.LinkButtonView.visuallySqueezed_marginAboveLabelForUnderneathField_textInputView,
				width: self.createNewContact_buttonView!.frame.size.width,
				height: self.createNewContact_buttonView!.frame.size.height
			)
		}
		if self.addPaymentID_buttonView.isHidden == false {
			let lastMostVisibleView: UIView
			do {
				if self.createNewContact_buttonView.isHidden == false {
					lastMostVisibleView = self.createNewContact_buttonView
				} else {
					lastMostVisibleView = self.requestFrom_inputView
				}
			}
			self.addPaymentID_buttonView!.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + UICommonComponents.LinkButtonView.visuallySqueezed_marginAboveLabelForUnderneathField_textInputView,
				width: self.addPaymentID_buttonView!.frame.size.width,
				height: self.addPaymentID_buttonView!.frame.size.height
			)
		}
		//
		if self.manualPaymentID_label.isHidden == false {
			assert(self.addPaymentID_buttonView.isHidden == true)
			//
			let lastMostVisibleView: UIView
			do {
				if self.createNewContact_buttonView.isHidden == false {
					lastMostVisibleView = self.createNewContact_buttonView
				} else {
					lastMostVisibleView = self.requestFrom_inputView
				}
			}
			self.manualPaymentID_label.frame = CGRect(
				//x: label_x,
				x: CGFloat(-5000),
				y: lastMostVisibleView.frame.origin.y + lastMostVisibleView.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
				width: 0,
				height: self.manualPaymentID_label.frame.size.height
			).integral
			self.manualPaymentID_label.sizeToFit() // get exact width
			if self.generatePaymentID_linkButtonView.frame.size.width != 0 {
				self.generatePaymentID_linkButtonView.sizeToFit() // only needs to be done once
			}
			self.generatePaymentID_linkButtonView.frame = CGRect(
				//x: self.manualPaymentID_label.frame.origin.x + self.manualPaymentID_label.frame.size.width + 8,
				x: CGFloat(-5000),
				y: self.manualPaymentID_label.frame.origin.y - abs(self.generatePaymentID_linkButtonView.frame.size.height - self.manualPaymentID_label.frame.size.height)/2,
				width: self.generatePaymentID_linkButtonView.frame.size.width,
				height: self.generatePaymentID_linkButtonView.frame.size.height
				).integral
			self.manualPaymentID_inputView.frame = CGRect(
				//x: input_x,
				x: CGFloat(-5000),
				y: self.manualPaymentID_label.frame.origin.y + self.manualPaymentID_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
				width: textField_w,
				height: self.manualPaymentID_inputView.frame.size.height
			).integral
		}
		//
		let bottomMostView: UIView
		bottomMostView = self.confirmSendFunds_buttonView
		
		let bottomPadding: CGFloat = 18
		self.scrollableContentSizeDidChange(
			withBottomView: bottomMostView,
			bottomPadding: bottomPadding
		)
	}
	override func viewDidAppear(_ animated: Bool)
	{
		let isFirstAppearance = self.hasAppearedBefore == false
		super.viewDidAppear(animated)
		if isFirstAppearance {
//			DispatchQueue.main.async
//			{ [unowned self] in
//				if self.sanitizedInputValue__selectedContact == nil {
//					assert(self.requestFrom_inputView.inputField.isHidden == false)
//					self.requestFrom_inputView.inputField.becomeFirstResponder()
//				}
//			}
		}
	}
	//
	// Delegation - Amounts.InputField UITextField shunt
	func textField(
		_ textField: UITextField,
		shouldChangeCharactersIn range: NSRange,
		replacementString string: String
	) -> Bool {
		if textField == self.amount_fieldset.inputField { // to support filtering characters
			return self.amount_fieldset.inputField.textField(
				textField,
				shouldChangeCharactersIn: range,
				replacementString: string
			)
		}
		return true
	}
	
	// Handler functions for sending
//	func validation_status_fn
//	func cancelled_fn
//	func handle_response_fn
	// Delegation - Interactions
	@objc func tapped_sendFunds()
	{
		debugPrint("Tapped sendfunds")
		debugPrint(self.selectedWallet!)
		debugPrint("Try send funds")
		self.confirmSendFunds_buttonView.isEnabled = false
		self.aFormSubmissionButtonWasPressed()
		
	}
	@objc func tapped_rightBarButtonItem()
	{
		debugPrint("tapped_rightBarButtonItem")
		self.aFormSubmissionButtonWasPressed()
	}
	@objc func tapped_barButtonItem_cancel()
	{
		assert(self.navigationController!.presentingViewController != nil)
		// we always expect self to be presented modally
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	//
	@objc func createNewContact_tapped()
	{
		let viewController = AddContactFromOtherTabFormViewController()
		viewController.didSave_instance_fn =
		{ [unowned self] (instance) in
			self.requestFrom_inputView.pick(contact: instance) // not going to call AtRuntime_reconfigureWith_fromContact() here because that's for user actions like Request where they're expecting the contact to be the initial state of self instead of this, which is initiated by their action from a modal that is nested within self
		}
		let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .formSheet
		self.navigationController!.present(navigationController, animated: true, completion: nil)
	}
	@objc func addPaymentID_tapped()
	{
		self.set_manualPaymentIDField(isHidden: false)
		self.addPaymentID_buttonView.isHidden = true
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) // to be slightly less jarring
		{ [unowned self] in
			self.manualPaymentID_inputView.becomeFirstResponder()
		}
	}
	@objc func tapped_generatePaymentID()
	{
		self.manualPaymentID_inputView.text = MyMoneroCore_ObjCpp.new_short_plain_paymentID()
	}
}
