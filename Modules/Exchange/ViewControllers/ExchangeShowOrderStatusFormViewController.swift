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
	var confirmSendFunds_buttonView: UICommonComponents.LinkButtonView!
	var btcAddress: String!
	weak var orderTimer: Timer?
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
	
	@objc func updateTimer() {
		
			//self.timeRemaining_inputView.text =
			// Time has expired
			let now = Date()
			
			if (now > self.expiryDate!) {
				debugPrint("Time epxired")
				stopTimer()
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
	
	@objc func startTimer()
	{
		orderTimer?.invalidate()
		orderTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
	}

	@objc func stopTimer() {
		orderTimer?.invalidate()
	}
	
	deinit {
		stopTimer()
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
		
		// ^ this will call setup (synchronously)
//		if contact != nil {
//			// wait or else animation on resolving indicator will fail
//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute:
//			{ [weak self] in
//				guard let thisSelf = self else {
//					return
//				}
//				thisSelf.requestFrom_inputView.pick(contact: contact!)
//			})
//		}
		self.selectedWallet = selectedWallet
		self.orderDetails = orderDetails
	
		debugPrint(orderDetails)
		debugPrint(orderDetails["in_amount"])
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
				case .success(let value):
					debugPrint(value["in_currency"])
					debugPrint("Ya")
					self.uuid_inputView.text = value["provider_order_id"] as? String
					self.orderStatus_inputView.text = value["status"] as? String
					self.currencyValuePayout_inputView.text = value["out_amount"] as? String
					self.remainingCurrencyPayable_inputView.text = value["in_amount"] as? String
					let expiryStr = value["expires_at"] as? String
					//self.expiryDate = Date(value["expires_at"] as! String)
					// Set up timer
					debugPrint(expiryStr)
					debugPrint(expiryStr)
					var dateFormatter = ISO8601DateFormatter()
					
					
					self.expiryDate = dateFormatter.date(from: expiryStr!)
					
					// if not nil, we have a valid date, and we can go ahead and

					
					let calendar = Calendar.current
					let now = Date()
					let difference = calendar.dateComponents([.hour, .minute, .second], from: Date(), to: self.expiryDate!)
					
					if self.expiryDate != nil {
						self.startTimer()
					}
					debugPrint(difference)
					
					
					//2020-11-05T10:46:15Z
					// we need an error output area
					
//
/*
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
			var confirmSendFunds_buttonView: UICommonComponents.LinkButtonView!
			
			"expires_at" = "2020-11-05T10:46:15Z";
			"in_address" = 8ATcH57zBGoda8WH2TV4GfPj4KQKMkC4CgrDbB9zEoZGc3LW9u4jEgK9DjoL3zo83JDs4tUmwwseoSi73CqVMiBE54VUYRu;
			"in_amount" = "0.2297";
			"in_amount_remaining" = "0.2297";
			"in_currency" = XMR;
			"order_id" = "a812-xmrto-RcnqG9";
			"out_address" = 3E6iM3nAY2sAyTqx5gF6nnCvqAUtMyRGEm;
			"out_amount" = "0.0017563";
			"out_currency" = BTC;
			"provider_name" = "xmr.to";
			"provider_order_id" = "xmrto-RcnqG9";
			"provider_url" = "https://xmr.to/";
			status = NEW;
			
			*/
					//let viewController = ExchangeShowOrderStatusFormViewController(selectedWallet: self.fromWallet_inputView.selectedWallet, orderDetails: value)
					//let modalViewController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
					//modalViewController.modalPresentationStyle = .formSheet
					//self.navigationController!.present(modalViewController, animated: true, completion: nil)
			}
		}
		
//		if selectedWallet != nil {
//			self.toWallet_inputView.set(selectedWallet: selectedWallet!)
//		}


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
			Please note that MyMonero cannot provide support for any exchanges. For all issues, please contact XMR.to with your UUID, as they will be able to assist.
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
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("Placeholder", comment: ""))
			self.uuid_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "Time Remaining")
			self.timeRemaining_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("timeremaining", comment: ""))
			self.timeRemaining_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "XMR payable")
			self.remainingCurrencyPayable_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("xmrpayable", comment: ""))
			self.remainingCurrencyPayable_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "BTC to be received")
			self.currencyValuePayout_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("btcout", comment: ""))
			self.currencyValuePayout_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.Form.FieldLabel(title: "Order Status")
			self.orderStatus_label = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.FormInputField(placeholder: NSLocalizedString("orderstatusgoeshere", comment: ""))
			self.orderStatus_inputView = view
			self.scrollView.addSubview(view)
		}
		do {
			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("Send Funds", comment: ""))
			view.addTarget(self, action: #selector(tapped_sendFunds), for: .touchUpInside)
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
		self.toWallet_inputView.set(isEnabled: false)
		
		self.amount_fieldset.inputField.isEnabled = false
		self.amount_fieldset.currencyPickerButton.isEnabled = false
		
		self.memo_inputView.isEnabled = false
		self.requestFrom_inputView.inputField.isEnabled = false
		if let pillView = self.requestFrom_inputView.selectedContactPillView {
			pillView.xButton.isEnabled = true
		}
		self.manualPaymentID_inputView.isEnabled = false
		self.generatePaymentID_linkButtonView.isEnabled = false
	}
	override func reEnableForm()
	{
		super.reEnableForm()
		//
		self.scrollView.isScrollEnabled = true
		//
		self.toWallet_inputView.set(isEnabled: true)
		
		self.amount_fieldset.inputField.isEnabled = true
		self.amount_fieldset.currencyPickerButton.isEnabled = true
		
		self.memo_inputView.isEnabled = true
		self.requestFrom_inputView.inputField.isEnabled = true
		if let pillView = self.requestFrom_inputView.selectedContactPillView {
			pillView.xButton.isEnabled = true
		}
		self.manualPaymentID_inputView.isEnabled = true
		self.generatePaymentID_linkButtonView.isEnabled = true
	}
	var formSubmissionController: ExchangeSendFundsForm? // TODO: maybe standardize into FormViewController
	
//	override func _tryToSubmitForm()
//	{
//		self.clearValidationMessage()
//		//
//		let toWallet = self.toWallet_inputView.selectedWallet!
//		if toWallet.didFailToInitialize_flag == true {
//			self.setValidationMessage(NSLocalizedString("Unable to load that wallet.", comment: ""))
//			return
//		}
//		if toWallet.didFailToBoot_flag == true {
//			self.setValidationMessage(NSLocalizedString("Unable to log into that wallet.", comment: ""))
//			return
//		}
//		//
//		let amount = self.amount_fieldset.inputField.text // we're going to allow empty amounts
//		if amount != nil && amount!.isPureDecimalNoGroupingNumeric == false {
//			self.setValidationMessage(NSLocalizedString("Please enter an amount with only numbers and the '.' character.", comment: ""))
//			return
//		}
//		let submittableDoubleAmount = self.amount_fieldset.inputField.submittableAmountRawDouble_orNil
//		do {
//			assert(submittableDoubleAmount != nil || amount == nil || amount == "")
//			if submittableDoubleAmount == nil && (amount != nil && amount != "") { // something entered but not usable
//				self.setValidationMessage(NSLocalizedString("Please enter a valid amount of Monero.", comment: ""))
//				return
//			}
//		}
//		if submittableDoubleAmount != nil && submittableDoubleAmount! <= 0 {
//			self.setValidationMessage(NSLocalizedString("Please enter an amount greater than zero.", comment: ""))
//			return
//		}
//		var submittableAmountFinalString: String?
//		if submittableDoubleAmount != nil {
//			submittableAmountFinalString = amount!
//			if amount!.first! == "." {
//				submittableAmountFinalString = "0" + submittableAmountFinalString!
//			}
//			if submittableAmountFinalString!.last! == ".".first! {
//				submittableAmountFinalString! += "0"
//			}
//		}
//		let submittable_amountCurrency: CcyConversionRates.CurrencySymbol? = submittableAmountFinalString != nil && submittableAmountFinalString! != "" ? self.amount_fieldset.currencyPickerButton.selectedCurrency.symbol : nil
//		//
//		let selectedContact = self.requestFrom_inputView.selectedContact
//		let hasPickedAContact = selectedContact != nil
//		let requestFrom_input_text = self.requestFrom_inputView.inputField.text
//		if requestFrom_input_text != nil && requestFrom_input_text! != "" { // they have entered something
//			if hasPickedAContact == false { // but not picked a contact
//				self.setValidationMessage(NSLocalizedString("Please select a contact or clear the contact field below to generate this request.", comment: ""))
//				return
//			}
//		}
//		let fromContact_name_orNil = selectedContact != nil ? selectedContact!.fullname : nil
//		//
//		let paymentID: MoneroPaymentID? = self.manualPaymentID_inputView.isHidden == false ? self.manualPaymentID_inputView.text : nil
//		let memoString = self.memo_inputView.text
//		let parameters = AddFundsRequestFormSubmissionController.Parameters(
//			optl__toWallet_color: toWallet.swatchColor,
//			toWallet_address: toWallet.public_address,
//			optl__fromContact_name: fromContact_name_orNil,
//			paymentID: paymentID,
//			amount: submittableAmountFinalString, // rather than using amount directly
//			optl__memo: memoString,
//			amountCurrency: submittable_amountCurrency,
//			//
//			preSuccess_terminal_validationMessage_fn:
//			{ [unowned self] (localizedString) in
//				self.setValidationMessage(localizedString)
//				self.formSubmissionController = nil // must free as this is a terminal callback
//				self.set_isFormSubmittable_needsUpdate()
//				self.reEnableForm() // b/c we disabled it
//			},
//			success_fn:
//			{ [unowned self] (instance) in
//				self.formSubmissionController = nil // must free as this is a terminal callback
//				self.reEnableForm() // b/c we disabled it
//				self._didSave(instance: instance)
//			}
//		)
//		let controller = SendFundsForm(parameters: parameters)
//		self.formSubmissionController = controller
//		do {
//			self.disableForm()
//			self.set_isFormSubmittable_needsUpdate() // update submittability
//		}
//		controller.handle()
//	}
//	//
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
			self.disclaimer_label.sizeToFit()
		}
		do {
			self.uuid_label.frame = CGRect(
				x: label_x,
				y: self.disclaimer_label.frame.origin.y + self.uuid_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
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
//		do {
//			self.confirmSendFunds_buttonView
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
		do {
			if self.manualPaymentID_inputView.isHidden == false {
				bottomMostView = self.manualPaymentID_inputView
			} else if self.addPaymentID_buttonView.isHidden == false {
				bottomMostView = self.addPaymentID_buttonView
			} else if self.createNewContact_buttonView.isHidden == false {
				bottomMostView = self.createNewContact_buttonView
			} else {
				bottomMostView = self.requestFrom_inputView
			}
		}
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
		
		
		// Once all is tested and working, invoke the following:
		/*
		wallet.SendFunds(
			enteredAddressValue,
			resolvedAddress,
			manuallyEnteredPaymentID,
			resolvedPaymentID,
			hasPickedAContact,
			resolvedAddress_fieldIsVisible,
			manuallyEnteredPaymentID_fieldIsVisible,
			resolvedPaymentID_fieldIsVisible,
			contact_payment_id,
			cached_OAResolved_address,
			contact_hasOpenAliasAddress,
			contact_address,
			raw_amount_string,
			sweeping,
			simple_priority,
			validation_status_fn,
			cancelled_fn,
			handle_response_fn
		);*/
		
		/*
			/*
							* We define the status update and the response handling function here, since we need to update the DOM with status feedback from the monero-daemon.
							* We pass them as the final argument to ExchangeUtils.sendFunds
							* It performs the necessary DOM-based status updates in this file so that we don't tightly couple DOM updates to a Utility module.
							*/
							function validation_status_fn(str)
							{

								let monerodUpdates = document.getElementById('monerod-updates')
								monerodUpdates.innerText = str;
							}
							/*
							* We perform the necessary DOM-based status updates in this file so that we don't tightly couple DOM updates to a Utility module.
							*/
							function handle_response_fn(err, mockedTransaction)
							{
								let str;
								let monerodUpdates = document.getElementById('monerod-updates');
								if (err) {
									str = typeof err === 'string' ? err : err.message;
									monerodUpdates.innerText = str;
									return
								}
								str = "Sent successfully.";
								monerodUpdates.innerText = str;
							}
							let xmr_amount = document.getElementById('in_amount_remaining').innerHTML;
							let xmr_send_address = document.getElementById('receiving_subaddress').innerHTML;
							let xmr_amount_str = "" + xmr_amount;
							
							let selectedWallet = document.getElementById('selected-wallet');
							let selectorOffset = selectedWallet.dataset.walletoffset;
							let sweep_wallet = false; // TODO: Add sweeping functionality
							ExchangeUtils.sendFunds(self.context.wallets[selectorOffset], xmr_amount_str, xmr_send_address, sweep_wallet, validation_status_fn, handle_response_fn);
						});

			
			*/

		var enteredAddressValue: MoneroAddress? = "45am3uVv3gNGUWmMzafgcrAbuw8FmLmtDhaaNycit7XgUDMBAcuvin6U2iKohrjd6q2DLUEzq5LLabkuDZFgNrgC9i3H4Tm"
		var resolvedAddress: MoneroAddress?
		var manuallyEnteredPaymentID: MoneroPaymentID?
		var resolvedPaymentID: MoneroPaymentID?
		var hasPickedAContent: Bool = false
		
		var resolvedAddress_fieldIsVisible: Bool = false
		var manuallyEnteredPaymentID_fieldIsVisible: Bool = false
		var resolvedPaymentID_fieldIsVisible: Bool = false
		var contactPaymentID: MoneroPaymentID?
		var cached_OAResolved_address: String?
		var contact_hasOpenAliasAddress: Bool = false
		var contact_address: String?
		var raw_amount_string: String = "0.000001"
		var isSweeping: Bool = false
		var simple_priority: MoneroTransferSimplifiedPriority = .low
		var preSuccess_nonTerminal_validationMessageUpdate_fn: (_ localizedString: String) -> Void
		var preSuccess_terminal_validationMessage_fn: (_ localizedString: String) -> Void
		var preSuccess_passedValidation_willBeginSending: () -> Void
		var canceled_fn: () -> Void
		var success_fn: (
			_ mockedTransaction: MoneroHistoricalTransactionRecord,
			_ sentTo_address: MoneroAddress, // this may differ from enteredAddress.. e.g. std addr + short pid -> int addr
			_ isXMRAddressIntegrated: Bool, // regarding sentTo_address
			_ integratedAddressPIDForDisplay_orNil: MoneroPaymentID?
		) -> Void
//		var validation_status_fn: Typehere = validation_status_fn "",
//		var cancelled_fn: Typehere = cancelled_fn "",
//		var handle_response_fn: Typehere = handle_response_fn ""

		var selectedContact: Contact?
		
//		self.selectedWallet.sendFunds(
//			enteredAddressValue: enteredAddressValue,
//			resolvedAddress: resolvedAddress,
//			manuallyEnteredPaymentID: manuallyEnteredPaymentID,
//			resolvedPaymentID: resolvedPaymentID,
//			hasPickedAContact: false,
//			resolvedAddress_fieldIsVisible: resolvedAddress_fieldIsVisible,
//			manuallyEnteredPaymentID_fieldIsVisible: manuallyEnteredPaymentID_fieldIsVisible,
//			resolvedPaymentID_fieldIsVisible: resolvedPaymentID_fieldIsVisible,
//			//
//			contact_payment_id: selectedContact?.payment_id,
//			cached_OAResolved_address: selectedContact?.cached_OAResolved_XMR_address,
//			contact_hasOpenAliasAddress: selectedContact?.hasOpenAliasAddress,
//			contact_address: selectedContact?.address,
//			//
//			raw_amount_string: raw_amount_string,
//			isSweeping: isSweeping,
//			simple_priority: simple_priority,
//			//
//			didUpdateProcessStep_fn: { [weak self] (msg) in
//				guard let thisSelf = self else {
//					return
//				}
//				thisSelf.preSuccess_nonTerminal_validationMessageUpdate_fn(msg)
//			},
//			success_fn: { [weak self] (sentTo_address, isXMRAddressIntegrated, integratedAddressPIDForDisplay_orNil, final_sentAmount, sentPaymentID_orNil, tx_hash, tx_fee, tx_key, mockedTransaction) in
//				guard let thisSelf = self else {
//					return
//				}
//				// formulate a mocked/transient historical transaction for details view presentation, and see if we need to present an "Add Contact From Sent" screen based on whether they sent w/o using a contact
//				thisSelf._didSend(
//					sentTo_address: sentTo_address,
//					isXMRAddressIntegrated: isXMRAddressIntegrated,
//					integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
//					mockedTransaction: mockedTransaction
//				)
//			},
//			canceled_fn: { [weak self] in
//				guard let thisSelf = self else {
//					return
//				}
//				thisSelf.canceled_fn()
//			},
//			failWithErr_fn: { [weak self] (err_str) in
//				guard let thisSelf = self else {
//					return
//				}
//				thisSelf.preSuccess_terminal_validationMessage_fn(err_str)
//			}
//		)
		
		
		
		/*
			didUpdateProcessStep_fn: @escaping ((_ msg: String) -> Void),
			success_fn: @escaping (
				_ sentTo_address: MoneroAddress,
				_ isXMRAddressIntegrated: Bool,
				_ integratedAddressPIDForDisplay_orNil: MoneroPaymentID?,
				_ final_sentAmountWithoutFee: MoneroAmount,
				_ sentPaymentID_orNil: MoneroPaymentID?,
				_ tx_hash: MoneroTransactionHash,
				_ tx_fee: MoneroAmount,
				_ tx_key: MoneroTransactionSecKey,
				_ mockedTransaction: MoneroHistoricalTransactionRecord
			) -> Void,
			canceled_fn: @escaping () -> Void,
			failWithErr_fn: @escaping (
				_ err_str: String
			) -> Void
		*/
		
		
		/*
		didUpdateProcessStep_fn: { [weak self] (msg) in
			guard let thisSelf = self else {
				return
			}
			thisSelf.parameters.preSuccess_nonTerminal_validationMessageUpdate_fn(msg)
		},
		success_fn: { [weak self] (sentTo_address, isXMRAddressIntegrated, integratedAddressPIDForDisplay_orNil, final_sentAmount, sentPaymentID_orNil, tx_hash, tx_fee, tx_key, mockedTransaction) in
			guard let thisSelf = self else {
				return
			}
			// formulate a mocked/transient historical transaction for details view presentation, and see if we need to present an "Add Contact From Sent" screen based on whether they sent w/o using a contact
			thisSelf._didSend(
				sentTo_address: sentTo_address,
				isXMRAddressIntegrated: isXMRAddressIntegrated,
				integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil,
				mockedTransaction: mockedTransaction
			)
		},
		canceled_fn: { [weak self] in
			guard let thisSelf = self else {
				return
			}
			thisSelf.parameters.canceled_fn()
		},
		failWithErr_fn: { [weak self] (err_str) in
			guard let thisSelf = self else {
				return
			}
			thisSelf.parameters.preSuccess_terminal_validationMessage_fn(err_str)
		}
		
		**/
		
		
//		var contact_payment_id: MoneroPaymentID?
//		var cached_OAResolved_address
//		var contact_hasOpenAliasAddress
//		var contact_address
//		var raw_amount_string = "0.000001"
//		var sweeping: Bool = false
//		var simple_priority
		
//		var resolvedPaymentID: Typehere = resolvedPaymentID "",
//		var hasPickedAContact: Typehere = hasPickedAContact "",
//		var resolvedAddress_fieldIsVisible: Typehere = resolvedAddress_fieldIsVisible "",
//		var manuallyEnteredPaymentID_fieldIsVisible: Typehere = manuallyEnteredPaymentID_fieldIsVisible "",
//		var resolvedPaymentID_fieldIsVisible: Typehere = resolvedPaymentID_fieldIsVisible "",
//		var contact_payment_id: Typehere = contact_payment_id "",
//		var cached_OAResolved_address: Typehere = cached_OAResolved_address "",
				 
		 //let enteredAddressValue = ""
		
	 //		var wallet = fromWallet_inputView.selectedWallet?.sendFunds(enteredAddressValue: <#T##MoneroAddress?#>, resolvedAddress: <#T##MoneroAddress?#>, manuallyEnteredPaymentID: <#T##MoneroPaymentID?#>, resolvedPaymentID: <#T##MoneroPaymentID?#>, hasPickedAContact: <#T##Bool#>, resolvedAddress_fieldIsVisible: <#T##Bool#>, manuallyEnteredPaymentID_fieldIsVisible: <#T##Bool#>, resolvedPaymentID_fieldIsVisible: <#T##Bool#>, contact_payment_id: <#T##MoneroPaymentID?#>, cached_OAResolved_address: <#T##String?#>, contact_hasOpenAliasAddress: <#T##Bool?#>, contact_address: <#T##String?#>, raw_amount_string: <#T##String?#>, isSweeping: <#T##Bool#>, simple_priority: <#T##MoneroTransferSimplifiedPriority#>, didUpdateProcessStep_fn: <#T##((String) -> Void)##((String) -> Void)##(String) -> Void#>, success_fn: <#T##(MoneroAddress, Bool, MoneroPaymentID?, MoneroAmount, MoneroPaymentID?, MoneroTransactionHash, MoneroAmount, MoneroTransactionSecKey, MoneroHistoricalTransactionRecord) -> Void#>, canceled_fn: <#T##() -> Void#>, failWithErr_fn: <#T##(String) -> Void#>);
		//var wallet = fromWallet_inputView.selectedWallet?.sendFunds
		
//		var wallet = self.wallet.sendFunds(
//			enteredAddressValue: ,
//			resolvedAddress: ,
//			manuallyEnteredPaymentID: ,
//			resolvedPaymentID: ,
//			hasPickedAContact: ,
//			resolvedAddress_fieldIsVisible: ,
//			manuallyEnteredPaymentID_fieldIsVisible: ,
//			resolvedPaymentID_fieldIsVisible: ,
//			contact_payment_id: ,
//			cached_OAResolved_address: ,
//			contact_hasOpenAliasAddress: ,
//			contact_address: ,
//			raw_amount_string: ,
//			sweeping: ,
//			simple_priority: ,
//			validation_status_fn: ,
//			cancelled_fn: ,
//			handle_response_fn:
//		);
		
	}
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