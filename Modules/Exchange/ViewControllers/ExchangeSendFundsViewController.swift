//
//  ExchangeSendFundsViewController.swift
//  MyMonero
//
//  Created by Karl Buys on 2020/10/27.
//  Copyright © 2020 MyMonero. All rights reserved.
//
import UIKit
import ImageIO
import Alamofire
import Swift
import SwiftyJSON
import BigInt
//
struct ExchangeSendFundsForm
{
	static let rateAPI_domain = "cryptocompare.com"
}
//
extension String {
	var isInteger: Bool { return Int(self) != nil }
	var isFloat: Bool { return Float(self) != nil }
	var isDouble: Bool { return Double(self) != nil }
}

extension ExchangeSendFundsForm
{
	//
	class ViewController: UICommonComponents.FormViewController, DeleteEverythingRegistrant
	{
		//
		// Static - Shared singleton
				
		static let shared = ExchangeSendFundsForm.ViewController()
		//
		// Properties/Protocols - DeleteEverythingRegistrant
		var instanceUUID = UUID()
		func identifier() -> String { // satisfy DeleteEverythingRegistrant for isEqual
			return self.instanceUUID.uuidString
		}
		//
		// Properties - Initial - Runtime
		// KB here
		
		// KB end
		private let apiUrl = "https://api.mymonero.com:8443/cx/"
		var validRateInfoRetrieved: Bool = false;
		var validOfferRetrieved: Bool = false;
		//private let apiUrl = "https://stagenet-api.mymonero.rtfm.net/"
		
		func getRateInfo(completionHandler: @escaping (Alamofire.Result<[String: Any]>) -> Void) {
			debugPrint("In async init")
			performGetRateInfo() {
				response in
					debugPrint("Assigning result")
					debugPrint(response)
					//debugPrint(response!.in_min)
					//self.validRateInfoRetrieved = true;
					//self.in_min = json?[0]["in_min"].string
//				self.in_min = result.in_min
//					self.in_max = result["in_max"].floatValue
//					self.out_max = result["out_max"].floatValue
//					self.in_min = result["in_min"].floatValue
//					debugPrint(self.in_min)
//			}
//			performGetRateInfo(completion: completion) {
//				result in
//				if let data = result.data {
//					self.validRateInfoRetrieved = true;
//					//self.in_min = json?[0]["in_min"].string
//					self.in_min = json["in_min"].floatValue
//					self.in_max = json["in_max"].floatValue
//					self.out_max = json["out_max"].floatValue
//					self.in_min = json["in_min"].floatValue
//					debugPrint(self.in_min)
//				}
			}
		}
		
		func performGetRateInfo(completion: @escaping (Alamofire.Result<[String: Any]>) -> Void) { // https://stackoverflow.com/questions/29024703/error-handling-in-alamofire
			let params: [String: String] = ["in_currency": "XMR", "out_currency": "BTC"]
			debugPrint("Fired getInfo")
			let method = "get_info"
			let apiEndpoint = apiUrl + method
			Alamofire.request(apiEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default)
				.validate()
				.responseJSON {
					response in
					switch response.result {
					case .success(let value as [String: Any]):
						debugPrint("GRI here")
						debugPrint(value)
						completion(.success(value))

					case .failure(let error):
						completion(.failure(error))

					default:
						fatalError("received non-dictionary JSON response")
					}
				}
		}
		
		// Pair of async functions for retrieving order
		
		func createOrder(offerId: String!, out_amount: String!, completionHandler: @escaping (Result<[String: Any]>) -> Void) {
			performCreateOrder(offerId: offerId, out_amount: out_amount, completion: completionHandler)
		}
		
		func performCreateOrder(offerId: String!, out_amount: String!, completion: @escaping (Result<[String: Any]>) -> Void) {
			self.orderFormValidation_label.text = ""
			self.btcAddress_inputView.text = "3E6iM3nAY2sAyTqx5gF6nnCvqAUtMyRGEm"
	
			let params: [String: String] = [
				//"out_address": "3E6iM3nAY2sAyTqx5gF6nnCvqAUtMyRGEm",
				"out_address": self.btcAddress_inputView.text!,
				"refund_address": "45am3uVv3gNGUWmMzafgcrAbuw8FmLmtDhaaNycit7XgUDMBAcuvin6U2iKohrjd6q2DLUEzq5LLabkuDZFgNrgC9i3H4Tm",
				"in_currency": "XMR",
				"out_currency": "BTC",
				"offer_id": offerId,
				"out_amount": "0.00175630"
			]
			debugPrint(params)
			debugPrint("Fired getOffer")
			let method = "create_order"
			let apiEndpoint = apiUrl + method
			Alamofire.request(apiEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default)
				.validate()
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
		
		
		
		func validateStringIsValidFloat(input: String) -> Bool {
			debugPrint("Validating float");
			if (input.isFloat == true) {
				debugPrint("True")
				debugPrint(input)
				return true
			} else {
				debugPrint(input);
				debugPrint("NaN")
				
				return false
			}
			
		}
		
		func getOffer(in_amount: String?, callingElement: String?) { https://stackoverflow.com/questions/29024703/error-handling-in-alamofire
			if validateStringIsValidFloat(input: in_amount!) {
				self.orderFormValidation_label.text = ""
				var params: [String:String] = ["in_currency": "XMR", "out_currency": "BTC"]
				if callingElement! == "in" {
					params["in_amount"] =  in_amount!
				}
					
				else if callingElement! == "out" {
					params["out_amount"] = in_amount!
				}
				debugPrint(callingElement!)
				debugPrint("Params")
				debugPrint(params)
				let method = "get_offer"
				let apiEndpoint = apiUrl + method
				Alamofire.request(apiEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default)
					.responseJSON {
						response in
						if let data = response.data {
							if let json = try? JSON(data: data) {
								self.validOfferRetrieved = true
								debugPrint(json)
								debugPrint(callingElement)
								//self.in_min = json?[0]["in_min"].string
								debugPrint(json["out_amount"])
								debugPrint(json["in_amount"].stringValue)
								debugPrint("Error here")
								debugPrint(json["Error"])
								self.orderFormValidation_label.text = json["Error"].stringValue
								self.orderFormValidation_label.sizeToFit()
								self.offerId = json["offer_id"].stringValue
								self.in_amount = json["in_amount"].stringValue
								self.out_amount = json["out_amount"].stringValue
								
								debugPrint(json["in_amount"])
								if callingElement == "out" {
									self.inAmount_inputView.text = json["in_amount"].stringValue
								} else if callingElement == "in" {
									let out_amount = String(json["out_amount"].stringValue)
									debugPrint(in_amount)
									self.outAmount_inputView.text = json["out_amount"].stringValue
									//self.outAmount_inputView.text = in_amount
								}
							}
						}
					}
			} else {
				self.orderFormValidation_label.text = "Please enter a valid amount"
				debugPrint("Not a valid float")
				
			}
		}
//			Alamofire.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default)
//				.validate()
//				.responseJSON { response in
//					debugPrint("Response: \(response)")
//					guard response.result.isSuccess else {
//					   print("Error while fetching remote rooms: \(String(describing: response.result.error))")
//					   completion(nil)
//					   return
//					 }
//
//					debugPrint(response.result)
//					//self.in_max = response.result.in_min
//					//debugPrint(self.in_max)
//					 guard let value = response.result.value as? [String: Any],
//					   let rows = value["rows"] as? [[String: Any]] else {
//						 print("Malformed data received from fetchAllRooms service")
//						 completion(nil)
//						 return
//					 }
//					debugPrint(rows)
//
//				// add error handlers
//
//			}
//		}
		
		var offerId: String!
		var orderId: String!
		// KB - to-do: Make sure we don't exceed or go below the following four values (initialised by getInfo()
		var in_max: Float = 0.00000000;
		var in_min: Float = 0.00000000;
		var out_max: Float = 0.00000000;
		var out_min: Float = 0.00000000;
		var ratesRetrieved: Bool = false
		var formIsVisible: Bool = true
		var exchangeFunctions = ExchangeFunctions();
		// Floating point calculations get handled server-side, so we can use them as strings so as to not have to keep swapping type
		var in_currency = "XMR"
		var out_currency = "BTC"
		var in_amount = ""
		var out_amount = ""
		var btcAddress = ""
		var xmrToSend_label: UICommonComponents.Form.FieldLabel!
		var btcToSend_label: UICommonComponents.Form.FieldLabel!
		var inAmount_inputView: UICommonComponents.FormInputField!
		var inAmount_label: UICommonComponents.Form.FieldLabel!
		var outAmount_inputView: UICommonComponents.FormInputField!
		var outAmount_label: UICommonComponents.Form.FieldLabel!
		var btcAddress_label: UICommonComponents.Form.FieldLabel!
		var btcAddress_inputView: UICommonComponents.FormInputField!
		//var offerPageErrors_label: UICommonComponents.Form.FieldLabel!
		
		
		var fromWallet_label: UICommonComponents.Form.FieldLabel!
		var fromWallet_inputView: UICommonComponents.WalletPickerButtonFieldView!
		var fromWallet_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		
		var explanation_label: UICommonComponents.Form.Text!
		var orderFormValidation_label: UICommonComponents.Form.FieldLabel!
		var orderStatusValidation_label: UICommonComponents.Form.FieldLabel!
		//
		var orderDetails: [String:Any] = [:]
		var orderExists: Bool = false
		var orderStatusViewController: ExchangeShowOrderStatusFormViewController?
		
		var amount_label: UICommonComponents.Form.FieldLabel!
		var amount_fieldset: UICommonComponents.Form.Amounts.InputFieldsetView!
		var networkFeeEstimate_label: UICommonComponents.FormFieldAccessoryMessageLabel!
		var feeEstimate_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var sendTo_label: UICommonComponents.Form.FieldLabel!
		var sendTo_inputView: UICommonComponents.Form.ContactAndAddressPickerView!
		var isWaitingOnFieldBeginEditingScrollTo_sendTo = false // a bit janky
		var sendTo_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var addPaymentID_buttonView: UICommonComponents.LinkButtonView!
		//
		var manualPaymentID_label: UICommonComponents.Form.FieldLabel!
		var generatePaymentID_linkButtonView: UICommonComponents.LinkButtonView!
		var manualPaymentID_inputView: UICommonComponents.FormInputField!
		//
		var priority_label: UICommonComponents.Form.FieldLabel!
		var priority_inputView: UICommonComponents.Form.StringPicker.PickerButtonFieldView!
		var priority_tooltipSpawn_buttonView: UICommonComponents.TooltipSpawningLinkButtonView!
		//
		var resetOrder_buttonView: UICommonComponents.ActionButton!
		var qrPicking_actionButtons: UICommonComponents.QRPickingActionButtons!
		//
		
//		override func textFieldDidBeginEditing(_ textField: UITextField) {
//			print("ThisDidBeginEditting")
//		}
		
		func setOutAmount(outCurrencyAmount: Float) {
			let outString = NSString(format: "%.8f", outCurrencyAmount)
			debugPrint(outString)
			self.inAmount_inputView.set(placeholder: outString as String)
		}
		
		@objc override func textFieldDidBeginEditing(_ textField: UITextField) {
			self.shouldEnableFormSubmission()
			debugPrint("ThisDidBeginEditting")
			debugPrint("\(textField.text)")
		}
		@objc func inputAmount_Send(_ textField: UITextField) {
			// Try get wallet send to work from here
			self.shouldEnableFormSubmission()
			debugPrint("inputAmountSend")
			debugPrint(inAmount_inputView.text)
		}

		@objc func outAmount_Changed(_ textField: UITextField) {
			orderFormValidation_label.text = ""
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = NumberFormatter.Style.decimal
			if let inputValue = numberFormatter.number(from: textField.text!) {
				// We need to compare this to a BigInt Monero amount so that we don't invoke getOffer when the input value is greater than our wallet balance
//				let bigIntValue: BigInt = BigInt(inputValue.floatValue * 1000000000000)
//				debugPrint("BigInt value")
//				debugPrint(bigIntValue)
//
//				debugPrint("Wallet balance")
//				debugPrint(self.fromWallet_inputView.selectedWallet?.balanceAmount)
//
//				if inputValue.floatValue < out_min {
//					debugPrint("Case 1")
//					let responseStr = "You must convert at least \(out_min) BTC per transaction"
//					orderFormValidation_label.text = responseStr
//					return
//				}
//
//				if bigIntValue > self.fromWallet_inputView.selectedWallet!.balanceAmount {
//					debugPrint("Case 2")
//					let responseStr = "You cannot convert more than \(out_max) BTC per transaction"
//					orderFormValidation_label.text = responseStr
//					return
//				}
				orderFormValidation_label.text = ""
				self.getOffer(in_amount: textField.text, callingElement: "out")
			} else {
				// TODO: Add error handling
				debugPrint("Case 3")
			}
		}
		
		@objc func inAmount_Changed(_ textField: UITextField) {
			orderFormValidation_label.text = ""
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = NumberFormatter.Style.decimal
			if let inputValue = numberFormatter.number(from: textField.text!) {
				//let bigIntValue: BigInt = BigInt(inputValue.doubleValue * 1000000000000)
				// We won't be able to calculate this in advance in future, as new currency pairs become available
//				if inputValue.floatValue < in_min {
//					debugPrint("Case 1")
//					let responseStr = "You must convert at least \(in_min) XMR per transaction"
//					orderFormValidation_label.text = responseStr
//					return
//				}
//
//				if bigIntValue > self.fromWallet_inputView.selectedWallet!.balanceAmount {
//					debugPrint("Case 2")
//					debugPrint(bigIntValue)
//					debugPrint(self.fromWallet_inputView.selectedWallet!.balanceAmount)
//					let responseStr = "You cannot convert more XMR than you have"
//					orderFormValidation_label.text = responseStr
//					return
//				}
				self.getOffer(in_amount: textField.text, callingElement: "in")
			} else {
				// TODO: Add error handling
				debugPrint("Case 3")
			}
		}
		
		// Lifecycle - Init
		override init()
		{
			super.init()
			
		}
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		override func setup_views()
		{
			super.setup_views()
		
			// KB: We need exception handling on the getinfo loop
			do { // Explanation Label
				let view = UICommonComponents.Form.Text(
					title: NSLocalizedString("You can convert your XMR into BTC here", comment: ""),
					sizeToFit: true
				)
				self.explanation_label = view
				self.scrollView.addSubview(view)
			}
			do { // Order status validation l Label -- used on onder quotation page
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("", comment: ""),
					sizeToFit: true
				)
				
				self.orderFormValidation_label = view
				self.scrollView.addSubview(view)
			}
//			do { // This validation string should go in the modal -- Order status validation label -- KB -- We may need to put this in a different view controller
//				let view = UICommonComponents.Form.FieldLabel(
//					title: NSLocalizedString("ValidationOS", comment: ""),
//					sizeToFit: true
//				)
//				self.orderStatusValidation_label = view
//				self.scrollView.addSubview(view)
//			}
			do { // Label
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("FROM", comment: ""),
					sizeToFit: true
				)
				
				self.fromWallet_label = view
				self.scrollView.addSubview(view)
			}
			do { // Iterate through wallets
				let view = UICommonComponents.WalletPickerButtonFieldView(selectedWallet: nil)
				view.selectionUpdated_fn =
				{ [unowned self] in
					self.configure_amountInputTextGivenMaxToggledState()
				}
				
				self.fromWallet_inputView = view
				self.scrollView.addSubview(view)
			}
//			do { // Tooltip
//				let view = UICommonComponents.TooltipSpawningLinkButtonView(
//					tooltipText: NSLocalizedString(
//						"Monero makes transactions\nwith your \"available outputs\",\nso part of your balance will\nbe briefly locked and then\nreturned as change.",
//						comment: ""
//					)
//				)
//				view.tooltipDirectionFromOrigin = .right // since it's at the top of the page (it tries to go up on its own)
//				view.willPresentTipView_fn =
//				{ [unowned self] in
//					self.view.resignCurrentFirstResponder() // if any
//				}
//				self.fromWallet_tooltipSpawn_buttonView = view
//				self.scrollView.addSubview(view)
//			}
			do { // inAmount label
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("XMR AMOUNT", comment: ""),
					sizeToFit: true
				)
				
				self.inAmount_label = view
				self.scrollView.addSubview(view)
			}
			do { // In Amount
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("0.00", comment: "")
				)
				
				let inputField = view
				inputField.autocorrectionType = .no
				inputField.autocapitalizationType = .none
				inputField.keyboardType = UIKeyboardType.decimalPad
				inputField.delegate = self
				inputField.addTarget(self, action: #selector(inAmount_Changed), for: .editingChanged)
				//inputField.addTarget(self, action: #selector(inputAmount_Send), for: .editingChanged)
				inputField.returnKeyType = .next
				self.inAmount_inputView = view
				self.scrollView.addSubview(view)
			}
			//
			do { // outAmount label
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("BTC AMOUNT", comment: ""),
					sizeToFit: true
				)
				
				self.outAmount_label = view
				self.scrollView.addSubview(view)
			}
			do { // Out Amount
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("0.00", comment: "")
				)
				
				let inputField = view
				inputField.autocorrectionType = .no
				inputField.autocapitalizationType = .none
				inputField.keyboardType = UIKeyboardType.decimalPad
				inputField.delegate = self
				inputField.addTarget(self, action: #selector(outAmount_Changed), for: .editingChanged)
				inputField.addTarget(self, action: #selector(inputAmount_Send), for: .editingChanged)
				inputField.returnKeyType = .next
				self.outAmount_inputView = view
				self.scrollView.addSubview(view)
			}
			do {
				//let view =
			}
			do {
	//			let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("Send Funds", comment: ""))
	//			view.addTarget(self, action: #selector(tapped_sendFunds), for: .touchUpInside)
	//			self.confirmSendFunds_buttonView = view
	//			self.scrollView.addSubview(view)
				let view = UICommonComponents.ActionButton(pushButtonType: .action, isLeftOfTwoButtons: false)
				view.addTarget(self, action: #selector(tapped_resetOrder), for: .touchUpInside)
				view.setTitle(NSLocalizedString("Reset Order", comment: ""), for: .normal)
				view.accessibilityIdentifier = "button.resetOrder"
				//view.isHidden = true
				self.resetOrder_buttonView = view
				self.scrollView.addSubview(view)
			}
//			do {
//				let view = UICommonComponents.Form.Amounts.InputFieldsetView(
//					effectiveAmountLabelBehavior: .yieldingRawOrEffectiveMoneroOnlyAmount, // different from Funds Request form
//					effectiveAmountTooltipText_orNil: String(
//						format: NSLocalizedString(
//							"Currency selector for\ndisplay purposes only.\nThe app will send %@.\n\nRate providers include\n%@.",
//							comment:"Currency selector for\ndisplay purposes only.\nThe app will send {XMR symbol}.\n\nRate providers include\n{cryptocompare.com domain}."
//						),
//						CcyConversionRates.Currency.XMR.symbol,
//						SendFundsForm.rateAPI_domain // not .authority - don't need subdomain
//					),
//					wantsMAXbutton: true
//				)
//				let inputField = view.inputField
//				inputField.delegate = self
//				inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
//				inputField.returnKeyType = .next
//
////				view.didUpdateValueAvailability_fn =
////				{ [weak self] in
////					// this will be called when the ccyConversion rate changes and when the selected currency changes
////					guard let thisSelf = self else {
////						return
////					}
////					thisSelf.set_isFormSubmittable_needsUpdate() // wait for ccyConversion rate to come in from what ever is supplying it
////					// TODO: do we need to update anything else here?
////				}
////				view.didUpdateMAXButtonToggleState_fn =
////				{ [weak self] in
////					guard let thisSelf = self else {
////						return
////					}
////					thisSelf.configure_amountInputTextGivenMaxToggledState()
////					thisSelf.set_isFormSubmittable_needsUpdate()
////				}
//				self.amount_fieldset = view
//				self.scrollView.addSubview(view)
//			}
			do {
				let view = UICommonComponents.FormFieldAccessoryMessageLabel(
					text: nil,
					displayMode: .prominent // slightly brighter here per design; considered merging
				)
				
//				view.adjustsFontSizeToFitWidth = true
//				view.minimumScaleFactor = 0.8
				self.networkFeeEstimate_label = view
				self.scrollView.addSubview(view)
			}
			do {
				let view = UICommonComponents.TooltipSpawningLinkButtonView(
					tooltipText: String(
						format: NSLocalizedString(
							"Based on Monero network\nfee estimate (not final).\n\nMyMonero does not charge\na transfer service fee.",
							comment: ""
						)
					)
				)
				
				view.willPresentTipView_fn =
				{ [unowned self] in
					self.view.resignCurrentFirstResponder() // if any
				}
				self.feeEstimate_tooltipSpawn_buttonView = view
				self.scrollView.addSubview(view)
			}
			//
//			do {
//				let view = UICommonComponents.Form.FieldLabel(
//					title: NSLocalizedString("TO", comment: ""),
//					sizeToFit: true
//				)
//				self.sendTo_label = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let view = UICommonComponents.TooltipSpawningLinkButtonView(
//					tooltipText: String(
//						format: NSLocalizedString(
//							"Please double-check\nyour recipient info as\nMonero transfers are\nnot yet reversible.",
//							comment: ""
//						)
//					)
//				)
//				view.tooltipDirectionFromOrigin = .right
//				view.willPresentTipView_fn =
//				{ [unowned self] in
//					self.view.resignCurrentFirstResponder() // if any
//				}
//				self.sendTo_tooltipSpawn_buttonView = view
//				self.scrollView.addSubview(view)
//			}
			
			do { // btcAddress label
				let view = UICommonComponents.Form.FieldLabel(
					title: NSLocalizedString("BTC ADDRESS", comment: ""),
					sizeToFit: true
				)
				
				self.btcAddress_label = view
				self.scrollView.addSubview(view)
			}
			do { // Out Amount
				let view = UICommonComponents.FormInputField(
					placeholder: NSLocalizedString("", comment: "")
				)
				
				let inputField = view
				inputField.autocorrectionType = .no
				inputField.autocapitalizationType = .none
				inputField.keyboardType = UIKeyboardType.asciiCapable
				inputField.delegate = self
				inputField.addTarget(self, action: #selector(btcAddress_changed), for: .editingChanged)
				inputField.returnKeyType = .next
			
				self.btcAddress_inputView = view
				self.scrollView.addSubview(view)
			}
			
			self.getRateInfo() {
				result in
				debugPrint("GRI() fired")
				switch result {
					case .failure (let error):
						self.orderFormValidation_label.text = "An error was encountered: \(error)"
						self.orderFormValidation_label.sizeToFit()
						let bottomPadding: CGFloat = 18
						self.scrollableContentSizeDidChange(
							withBottomView: self.orderFormValidation_label,
							bottomPadding: bottomPadding
						)
						//self.set_formIsVisible(isHidden: false)
						debugPrint(error)
						// show retry button
					case .success(let value):
						debugPrint(value)
						debugPrint("Successfully retrieved rates")
					}
			}
			//
//			do {
//				let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .hidden, title: NSLocalizedString("+ ADD PAYMENT ID", comment: ""))
//				view.addTarget(self, action: #selector(addPaymentID_tapped), for: .touchUpInside)
//				self.addPaymentID_buttonView = view
//
//				self.scrollView.addSubview(view)
//			}
//			//
//			do {
//				let view = UICommonComponents.Form.FieldLabel(
//					title: NSLocalizedString("ENTER PAYMENT ID OR", comment: "")
//				)
//				view.isHidden = true // initially
//				self.manualPaymentID_label = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let view = UICommonComponents.LinkButtonView(mode: .mono_default, size: .normal, title: NSLocalizedString("GENERATE ONE", comment: ""))
//				view.addTarget(self, action: #selector(tapped_generatePaymentID), for: .touchUpInside)
//				view.isHidden = true // initially
//				self.generatePaymentID_linkButtonView = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let view = UICommonComponents.FormInputField(
//					placeholder: NSLocalizedString("A specific payment ID", comment: "")
//				)
//				view.isHidden = true // initially
//				let inputField = view
//				inputField.autocorrectionType = .no
//				inputField.autocapitalizationType = .none
//				inputField.delegate = self
//				inputField.addTarget(self, action: #selector(aField_editingChanged), for: .editingChanged)
//				inputField.returnKeyType = .next
//				self.manualPaymentID_inputView = view
//				self.scrollView.addSubview(view)
//			}
//			//
//			do {
//				let view = UICommonComponents.Form.FieldLabel(
//					title: NSLocalizedString("TRANSFER", comment: ""),
//					sizeToFit: true
//				)
//				self.priority_label = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let view = UICommonComponents.TooltipSpawningLinkButtonView(
//					tooltipText: NSLocalizedString(
//						"You can pay the Monero\nnetwork a higher fee to\nhave your transfers\nconfirmed faster.",
//						comment: ""
//					)
//				)
//				view.willPresentTipView_fn =
//				{ [unowned self] in
//					self.view.resignCurrentFirstResponder() // if any
//				}
//				self.priority_tooltipSpawn_buttonView = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let view = UICommonComponents.Form.StringPicker.PickerButtonFieldView(
//					title: NSLocalizedString("Priority", comment: ""),
//					selectedValue: MoneroTransferSimplifiedPriority.defaultPriority.humanReadableCapitalizedString,
//					allValues: MoneroTransferSimplifiedPriority.allValues_humanReadableCapitalizedStrings
//				)
//				view.picker_inputField_didBeginEditing =
//				{ [weak self] (inputField) in
//					DispatchQueue.main.asyncAfter( // slightly janky
//						deadline: .now() + UICommonComponents.FormViewController.fieldScrollDuration + 0.1
//					) { [weak self] in
//						guard let thisSelf = self else {
//							return
//						}
//						if inputField.isFirstResponder { // jic
//							thisSelf.scrollInputViewToVisible(thisSelf.priority_inputView)
//						}
//					}
//				}
//				view.selectedValue_fn =
//				{ [weak self] in
//					guard let thisSelf = self else {
//						return
//					}
//					thisSelf.configure_networkFeeEstimate_label()
//					thisSelf.configure_amountInputTextGivenMaxToggledState()
//				}
//				self.priority_inputView = view
//				self.scrollView.addSubview(view)
//			}
//			do {
//				let buttons = UICommonComponents.QRPickingActionButtons(
//					containingViewController: self,
//					attachingToView: self.view // not self.scrollView
//				)
//				buttons.havingPickedImage_shouldAllowPicking_fn =
//				{ [weak self] in
//					guard let thisSelf = self else {
//						return false
//					}
//					if thisSelf.isFormEnabled == false {
//						DDLog.Warn("SendFundsTab", "Disallowing QR code pick while form disabled")
//						return false
//					}
//					return true
//				}
//				buttons.willDecodePickedImage_fn =
//				{ [weak self] in
//					guard let thisSelf = self else {
//						return
//					}
//					thisSelf.clearValidationMessage() // in case there was a parsing err etc displaying
//				}
//				buttons.didPick_fn =
//				{ [weak self] (possibleUriString) in
//					guard let thisSelf = self else {
//						return
//					}
//					thisSelf.__shared_didPick(possibleRequestURIStringForAutofill: possibleUriString)
//				}
//				buttons.didEndQRScanWithErrStr_fn =
//				{ [weak self] (localizedValidationMessage) in
//					guard let thisSelf = self else {
//						return
//					}
//					thisSelf.set(validationMessage: localizedValidationMessage, wantsXButton: true)
//				}
//				self.qrPicking_actionButtons = buttons
//			}
			//
			// initial configuration; now that references to both the fee estimate layer and the priority select control have been assigned…
			self.configure_networkFeeEstimate_label()
			//self.configure_amountInputTextGivenMaxToggledState()
		}
		override func setup_navigation()
		{
			super.setup_navigation()
			self.navigationItem.title = NSLocalizedString("Exchange XMR", comment: "")
			self.navigationItem.rightBarButtonItem = UICommonComponents.NavigationBarButtonItem(
				type: .createExchangeOrder,
				target: self,
				action: #selector(tapped_createOrderRightBarButtonItem)
			)
		}
		
		@objc func handleUserDidBecomeIdle() {
			debugPrint("we fired when the state became idle")
			debugPrint(self.offerId)
			debugPrint(self.in_amount)
			debugPrint(self.out_amount)
		}
		
		@objc func handleUserDidComeBack() {
			debugPrint("we fired when the state came back from idle")
			debugPrint(self.offerId)
			debugPrint(self.in_amount)
			debugPrint(self.out_amount)
		}
		
		override func startObserving()
		{
			super.startObserving()
			PasswordController.shared.addRegistrantForDeleteEverything(self)
			//
			NotificationCenter.default.addObserver(self, selector: #selector(URLOpening_saysTimeToHandleReceivedMoneroURL(_:)), name: URLOpening.NotificationNames.saysTimeToHandleReceivedMoneroURL.notificationName, object: nil)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(WalletAppContactActionsCoordinator_didTrigger_sendFundsToContact(_:)),
				name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_sendFundsToContact.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(WalletAppWalletActionsCoordinator_didTrigger_sendFundsFromWallet(_:)),
				name: WalletAppWalletActionsCoordinator.NotificationNames.didTrigger_sendFundsFromWallet.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(handleUserDidBecomeIdle),
				name: UserIdle.NotificationNames.userDidBecomeIdle.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(handleUserDidComeBack),
				name: UserIdle.NotificationNames.userDidComeBackFromIdle.notificationName, // observe 'did' so we're guaranteed to already be on right tab
				object: nil
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_willDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(PasswordController_didDeconstructBootedStateAndClearPassword),
				name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
				object: PasswordController.shared
			)
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(CcyConversionRates_didUpdateAvailabilityOfRates),
				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
				object: nil
			)
//			NotificationCenter.default.addObserver(
//				self,
//				selector: #selector(SettingsController__NotificationNames_Changed__displayCurrencySymbol),
//				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
//				object: nil
//			)
		}
		//
		override func tearDown()
		{
			super.tearDown()
		}
		override func stopObserving()
		{
			super.stopObserving()
			debugPrint("Stop observing parent stuff")
			// KB TODO: Fix up the stop observing stuff to clean properly -- we can clean everything except the order details
//			PasswordController.shared.removeRegistrantForDeleteEverything(self)
//			//
//			NotificationCenter.default.removeObserver(self, name: URLOpening.NotificationNames.saysTimeToHandleReceivedMoneroURL.notificationName, object: nil)
//
//			NotificationCenter.default.removeObserver(self, name: WalletAppContactActionsCoordinator.NotificationNames.didTrigger_sendFundsToContact.notificationName, object: nil)
//			//
//			NotificationCenter.default.removeObserver(
//				self,
//				name: PasswordController.NotificationNames.willDeconstructBootedStateAndClearPassword.notificationName,
//				object: PasswordController.shared
//			)
//			NotificationCenter.default.removeObserver(
//				self,
//				name: PasswordController.NotificationNames.didDeconstructBootedStateAndClearPassword.notificationName,
//				object: PasswordController.shared
//			)
//			//
//			NotificationCenter.default.removeObserver(
//				self,
//				name: CcyConversionRates.Controller.NotificationNames.didUpdateAvailabilityOfRates.notificationName,
//				object: nil
//			)
//			NotificationCenter.default.removeObserver(
//				self,
//				name: SettingsController.NotificationNames_Changed.displayCurrencySymbol.notificationName,
//				object: nil
//			)
		}
		//
		// Accessors - Overrides
		override func new_isFormSubmittable() -> Bool
		{
			if self.formSubmissionController != nil {
				return false
			}
			
			if self.inAmount_inputView.text?.isEmpty == true {
				return false
			}
			
			if self.outAmount_inputView.text?.isEmpty == true {
				return false
			}
			
			if self.btcAddress_inputView.text?.isEmpty == true {
				return false
			}
//			if self.sendTo_inputView.isResolving {
//				return false
//			}
//			if self.sendTo_inputView.isValidatingOrResolvingNonZeroTextInput {
//				return false
//			}
//			let submittableMoneroAmountDouble_orNil = self.amount_fieldset.inputField.submittableMoneroAmountDouble_orNil(
//				selectedCurrency: self.amount_fieldset.currencyPickerButton.selectedCurrency
//			)
//			if submittableMoneroAmountDouble_orNil == nil {
//				let isSweeping = self.amount_fieldset.maxButtonView!.isToggledOn
//				if isSweeping == false { // amount is required unless sweeping
//					return false
//				}
//			}
			// KB: handle form submittable here
//			if self.sendTo_inputView.hasValidTextInput_moneroAddress == false
//				&& self.sendTo_inputView.hasValidTextInput_resolvedOAAddress == false
//				&& self.sendTo_inputView.selectedContact == nil {
//				return false
//			}
			return true
		}
		override func new_contentInset() -> UIEdgeInsets
		{
			var inset = super.new_contentInset()
			inset.bottom += UICommonComponents.ActionButton.wholeButtonsContainerHeight
			
			return inset
		}
		//
		override func nextInputFieldViewAfter(inputView: UIView) -> UIView?
		{
			switch inputView {
			case self.fromWallet_inputView.picker_inputField:
				return self.amount_fieldset.inputField
			case self.amount_fieldset.inputField:
				if self.sendTo_inputView.inputField.isHidden == false {
					return self.sendTo_inputView.inputField
				} else if self.manualPaymentID_inputView.isHidden == false {
					return self.manualPaymentID_inputView
				}
				break
			case self.sendTo_inputView.inputField:
				if self.manualPaymentID_inputView.isHidden == false {
					return manualPaymentID_inputView
				}
				break
			case self.manualPaymentID_inputView:
				break
			default:
				assert(false, "Unexpected")
				return nil
			}
			return self.fromWallet_inputView.picker_inputField // wrap to start
		}
//		override func new_wantsBGTapRecognizerToReceive_tapped(onView view: UIView) -> Bool
//		{
//			if view.isAnyAncestor(self.sendTo_inputView) {
//				// this is to prevent taps on the searchResults tableView from dismissing the input (which btw makes selection of search results rows impossible)
//				// but it's ok if this is the inputField itself
//				return false
//			}
//			return super.new_wantsBGTapRecognizerToReceive_tapped(onView: view)
//		}
		//
		// Accessors
		var sanitizedInputValue__fromWallet: Wallet {
			return self.fromWallet_inputView.selectedWallet! // we are never expecting this modal to be visible when no wallets exist, so a crash is/ought to be ok
		}
		var sanitizedInputValue__selectedContact: Contact? {
			return self.sendTo_inputView.selectedContact
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
		var selected_priority: MoneroTransferSimplifiedPriority {
			let selectedString = self.priority_inputView.selectedValue!
			let priority = MoneroTransferSimplifiedPriority.new_priority(fromHumanReadableString: selectedString)
			//
			return priority
		}
		var new_xmr_estFeeAmount: MoneroAmount {
			let estNetworkFee_moneroAmount = MyMoneroCore.ObjCppBridge.estimatedNetworkFee(
				withFeePerB: MoneroAmount("24658")!, // constant for now pending polling fee_per_kb on account info
				priority: MoneroTransferSimplifiedPriority.low
			)
			return estNetworkFee_moneroAmount
		}
		var new_xmr_estMaxAmount: MoneroAmount? { // may return nil if a wallet isn't present yet
			guard let wallet = self.fromWallet_inputView.selectedWallet else {
				return nil // no wallet yet
			}
			let availableWalletBalance = wallet.balanceAmount - wallet.lockedBalanceAmount // TODO: is it correct to incorporate locked balance into this?
			let estNetworkFee_moneroAmount = self.new_xmr_estFeeAmount
			if availableWalletBalance > estNetworkFee_moneroAmount {
				return availableWalletBalance - estNetworkFee_moneroAmount
			}
			return MoneroAmount("0") // can't actually send any of the balance - or maybe there are some dusty outputs that will come up in the actual sweep?99
		}
		var new_displayCcyFormatted_estMaxAmountString: String? { // this is going to return nil if the rate is not ready for the selected display currency - user will probably just have to keep hitting 'max'
			guard let xmr_estMaxAmount = self.new_xmr_estMaxAmount else {
				return nil
			}
			let displayCurrency = self.amount_fieldset.currencyPickerButton.selectedCurrency
			if displayCurrency != .XMR {
				let converted_amountDouble = displayCurrency.displayUnitsRounded_amountInCurrency(
					fromMoneroAmount: xmr_estMaxAmount
				)
				if converted_amountDouble == nil {
					return nil // rate not ready yet
				}
				return displayCurrency.nonAtomicCurrency_formattedString(
					final_amountDouble: converted_amountDouble!
				)
			}
			return xmr_estMaxAmount.formattedString // then it's an xmr amount
		}
		var new_displayCcyFormatted_estMaxAmount_fullInputText: String {
			guard let string = self.new_displayCcyFormatted_estMaxAmountString else {
				return NSLocalizedString("MAX", comment: "") // such as while rate not available
			}
			return "~ " + string // TODO: is this localized enough - consider writing direction
			// ^ luckily we can do this for long numbers because the field will right truncate it and then left align the text
		}
		//
		// Imperatives - Field visibility
		func set_manualPaymentIDField(isHidden: Bool)
		{
//			var touched: Bool = false
//			if self.manualPaymentID_label.isHidden != isHidden {
//				touched = true
//				self.manualPaymentID_label.isHidden = isHidden
//			}
//			if self.manualPaymentID_inputView.isHidden != isHidden {
//				touched = true
//				self.manualPaymentID_inputView.isHidden = isHidden
//			}
//			if self.generatePaymentID_linkButtonView.isHidden != isHidden {
//				touched = true
//				self.generatePaymentID_linkButtonView.isHidden = isHidden
//			}
//			if touched {
//				self.view.setNeedsLayout()
//			}
		}
		func set_inAmountField(isHidden: Bool)
		{
			var touched: Bool = false
			if self.inAmount_inputView.isHidden != isHidden {
				touched = true
				self.inAmount_inputView.isHidden = isHidden
			}
			if self.inAmount_inputView.isHidden != isHidden {
				touched = true
				self.inAmount_inputView.isHidden = isHidden
			}
			if self.inAmount_inputView.isHidden != isHidden {
				touched = true
				self.inAmount_inputView.isHidden = isHidden
			}
			if touched {
				self.view.setNeedsLayout()
			}
		}
		
		func set_formVisiblility(isHidden: Bool) {
			self.fromWallet_label.isHidden = isHidden
			self.fromWallet_inputView.isHidden = isHidden
			self.feeEstimate_tooltipSpawn_buttonView.isHidden = isHidden
			self.networkFeeEstimate_label.isHidden = isHidden
			self.inAmount_inputView.isHidden = isHidden
			self.outAmount_inputView.isHidden = isHidden
			self.btcAddress_inputView.isHidden = isHidden
			self.inAmount_label.isHidden = isHidden
			self.outAmount_label.isHidden = isHidden
			self.btcAddress_label.isHidden = isHidden
			self.formIsVisible = isHidden
		}
		
		func show_inAmount_inputView(withValue paymentID: String?)
		{
			self.inAmount_inputView.text = paymentID ?? "" // nil to empty field
			self.set_inAmount_inputView(isHidden: false)
		}
		func set_inAmount_inputView(isHidden: Bool)
		{
			self.inAmount_inputView.isHidden = isHidden
			self.view.setNeedsLayout()
		}
		func hideAndClear_inAmount_inputView()
		{
			self.set_inAmount_inputView(isHidden: true)
			if self.inAmount_inputView.text != "" {
				self.inAmount_inputView.text = ""
			}
		}
		func show_manualPaymentIDField(withValue paymentID: String?)
		{
			self.manualPaymentID_inputView.text = paymentID ?? "" // nil to empty field
			self.set_manualPaymentIDField(isHidden: false)
		}
		func hideAndClear_manualPaymentIDField()
		{
			self.set_manualPaymentIDField(isHidden: true)
			if self.manualPaymentID_inputView.text != "" {
				self.manualPaymentID_inputView.text = ""
			}
		}
		//
		func set_addPaymentID_buttonView(isHidden: Bool)
		{
			self.addPaymentID_buttonView.isHidden = isHidden
			self.view.setNeedsLayout()
		}
		//
		// Imperatives - Configuration - Fee estimate label, Max amount, ...
		func configure_networkFeeEstimate_label()
		{
			let components = CcyConversionRates.Currency.amountConverted_displayStringComponents(
				from: self.new_xmr_estFeeAmount,
				ccy: SettingsController.shared.displayCurrency,
				chopNPlaces: UIFont.shouldStepDownLargerFontSizes ? 4 : 3 // for new high precision fees; TODO: is this future-proofed enough?
			)
			let text = String(
				format: NSLocalizedString("+ %@ %@ EST. FEE", comment: "+ {amount} {currency symbol} EST. FEE"),
				components.formattedAmount,
				components.final_ccy.symbol
			)
			self.networkFeeEstimate_label.text = text
			//
			self.view.setNeedsLayout() // we must reflow the tooltip's x
		}
		func configure_amountInputTextGivenMaxToggledState()
		{
//			let isMaxToggledOn = self.amount_fieldset.maxButtonView!.isToggledOn
//			let toToggledOnText: String? = isMaxToggledOn
//				? self.new_displayCcyFormatted_estMaxAmount_fullInputText // if non xmr ccy but rate nil (amount nil), will display "MAX" til it's ready
//				: nil
//			self.amount_fieldset.inputField.configureWithMAXToggled(
//				on: isMaxToggledOn,
//				toToggledOnText: toToggledOnText
//			)
		}
		//
		// Imperatives - Contact picker, contact picking
		func scrollToVisible_sendTo()
		{
			self.scrollInputViewToVisible(self.sendTo_inputView)
		}
		public func reconfigureFormAtRuntime_havingElsewhereSelected(sendToContact contact: Contact)
		{
			self.amount_fieldset.clear() // figure that since this method is called when user is trying to initiate a new request, we should clear the amount
			//
			self.sendTo_inputView.pick(contact: contact)
		}
		//
		// Runtime - Imperatives - Overrides
		override func disableForm()
		{
			super.disableForm()
			//
//			self.scrollView.isScrollEnabled = false
//			//
//			self.fromWallet_inputView.set(isEnabled: false)
//
//			self.amount_fieldset.inputField.isEnabled = false
//			self.amount_fieldset.currencyPickerButton.isEnabled = false
//
//			self.priority_inputView.set(isEnabled: false)
//
//			self.sendTo_inputView.inputField.isEnabled = false
//			if let pillView = self.sendTo_inputView.selectedContactPillView {
//				pillView.xButton.isEnabled = true
//			}
//			self.manualPaymentID_inputView.isEnabled = false
//			self.generatePaymentID_linkButtonView.isEnabled = false
//			self.addPaymentID_buttonView.isEnabled = false
//			//
//			self.qrPicking_actionButtons.set(isEnabled: false)
			
			self.btcAddress_inputView.isEnabled = false
			self.inAmount_inputView.isEnabled = false
			self.outAmount_inputView.isEnabled = false
			if (self.orderExists) {
				// We've created an order, so we want the top-right button to remain enabled so that we can navigate to the order again
				self.navigationItem.rightBarButtonItem?.isEnabled = true
				return
			}
			self.navigationItem.rightBarButtonItem?.isEnabled = false
		}
		
		@objc func shouldEnableFormSubmission() {
//			self.btcAddress_inputView.isEnabled = false
//			self.inAmount_inputView.isEnabled = false
//			self.outAmount_inputView.isEnabled = false
			if self.btcAddress_inputView.text?.isEmpty == false && self.inAmount_inputView.text?.isEmpty == false && self.outAmount_inputView.text?.isEmpty == false {
				self.navigationItem.rightBarButtonItem?.isEnabled = true
			} else {
				self.navigationItem.rightBarButtonItem?.isEnabled = false
			}
		}
		
		override func reEnableForm()
		{
			super.reEnableForm()
			//
			// allowing scroll so user can check while sending despite no cancel support existing yet
//			self.scrollView.isScrollEnabled = true
			//
//			self.fromWallet_inputView.set(isEnabled: true)
//
//			self.amount_fieldset.inputField.isEnabled = true
//			self.amount_fieldset.currencyPickerButton.isEnabled = true
//
//			self.priority_inputView.set(isEnabled: true)
//
//			self.sendTo_inputView.inputField.isEnabled = true
//			if let pillView = self.sendTo_inputView.selectedContactPillView {
//				pillView.xButton.isEnabled = true
//			}
//			self.inAmount_inputView.isEnabled = true
//			self.manualPaymentID_inputView.isEnabled = true
//			self.generatePaymentID_linkButtonView.isEnabled = true
//			self.addPaymentID_buttonView.isEnabled = true
//			//
//			self.qrPicking_actionButtons.set(isEnabled: true)
			self.btcAddress_inputView.isEnabled = true
			self.inAmount_inputView.isEnabled = true
			self.outAmount_inputView.isEnabled = true
		}
		var formSubmissionController: SendFundsForm.SubmissionController?
		override func _tryToSubmitForm()
		{
			self.clearValidationMessage()
			//
			let fromWallet = self.fromWallet_inputView.selectedWallet!
			//let isSweeping = self.amount_fieldset.maxButtonView!.isToggledOn
			//let amountText = self.amount_fieldset.inputField.text // we're going to allow empty amounts
			let amountText = self.inAmount_inputView.text
			
			if amountText != nil && amountText!.isPureDecimalNoGroupingNumeric == false {
				self.setValidationMessage(NSLocalizedString("Please enter an amount with only numbers and the '.' character.", comment: ""))
				return
			}
			let amount_submittableDouble = self.amount_fieldset.inputField.submittableMoneroAmountDouble_orNil(
				selectedCurrency: self.amount_fieldset.currencyPickerButton.selectedCurrency
			)
			//if isSweeping == false {
				assert(amount_submittableDouble != nil && amountText != nil && amountText != "")
				if amount_submittableDouble == nil {
					self.setValidationMessage(NSLocalizedString("Please enter a valid amount of Monero.", comment: ""))
					return
				}
				if amount_submittableDouble! <= 0 {
					self.setValidationMessage(NSLocalizedString("The amount to send must be greater than zero.", comment: ""))
					return
				}
			//}
			//
			let selectedCurrency = self.amount_fieldset.currencyPickerButton.selectedCurrency
			func __proceedTo_disableFormAndExecute()
			{
				self.disableForm() // optimistic
				//
				let selectedContact = self.sendTo_inputView.selectedContact
				let enteredAddressValue = self.sendTo_inputView.inputField.text
				//
				let resolvedAddress_fieldIsVisible = self.sendTo_inputView.resolvedXMRAddr_inputView != nil && self.sendTo_inputView.resolvedXMRAddr_inputView?.isHidden == false
				let resolvedAddress = resolvedAddress_fieldIsVisible ? self.sendTo_inputView.resolvedXMRAddr_inputView?.textView.text : nil
				//
				let manuallyEnteredPaymentID_fieldIsVisible = self.manualPaymentID_inputView.isHidden == false
				let manuallyEnteredPaymentID = manuallyEnteredPaymentID_fieldIsVisible ? self.manualPaymentID_inputView.text : nil
				//
				let resolvedPaymentID_fieldIsVisible = self.sendTo_inputView.resolvedPaymentID_inputView != nil && self.sendTo_inputView.resolvedPaymentID_inputView?.isHidden == false
				let resolvedPaymentID = resolvedPaymentID_fieldIsVisible ? self.sendTo_inputView.resolvedPaymentID_inputView?.textView.text ?? "" : nil
				//
				let priority = self.selected_priority
				//
				//assert(isSweeping || amount_submittableDouble != nil)
				assert(amount_submittableDouble != nil)
				let parameters = SendFundsForm.SubmissionController.Parameters(
					fromWallet: fromWallet,
					amount_submittableDouble: amount_submittableDouble,
					isSweeping: false,
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
						self.formSubmissionController = nil // must free as this is a terminal callback
						// will re-enable form shortly (after presentation)
						//
						do {
							let viewController = TransactionDetails.ViewController(
								transaction: mockedTransaction,
								inWallet: fromWallet
							)
							self.navigationController!.pushViewController(
								viewController,
								animated: true
							)
						}
						do { // and after a delay, present AddContactFromSendTabView
							if selectedContact == nil { // so they went with a text input address
								DispatchQueue.main.asyncAfter(
									deadline: .now() + 0.75 + 0.3, // after the navigation transition just above has taken place, and given a little delay for user to get their bearings
									execute:
									{ [unowned self] in
										let parameters = AddContactFromSendFundsTabFormViewController.InitializationParameters(
											enteredAddressValue: enteredAddressValue!,
											integratedAddressPIDForDisplay_orNil: integratedAddressPIDForDisplay_orNil, // NOTE: this will be non-nil if a short pid is supplied with a standard address - rather than an integrated addr alone being used
											resolvedAddress: resolvedAddress_fieldIsVisible ? resolvedAddress : nil,
											sentWith_paymentID: mockedTransaction.paymentId // will not be nil for integrated enteredAddress
										)
										let viewController = AddContactFromSendFundsTabFormViewController(
											parameters: parameters
										)
										let navigationController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
										navigationController.modalPresentationStyle = .formSheet
										self.navigationController!.present(navigationController, animated: true, completion: nil)
									}
								)
							}
						}
						do { // finally, clean up form
							DispatchQueue.main.asyncAfter(
								deadline: .now() + 0.5, // after the navigation transition just above has taken place
								execute:
								{ [unowned self] in
									self._clearForm()
									// and lastly, importantly, re-enable everything
									self.reEnableForm()
								}
							)
						}
					}
				)
				let controller = SendFundsForm.SubmissionController(parameters: parameters)
				self.formSubmissionController = controller
				do {
					self.disableForm()
					self.set_isFormSubmittable_needsUpdate() // update submittability; after setting self.submissionController
				}
				controller.handle()
			}
			//
			// now if using alternate display currency, be sure to ask for terms agreement before doing send
//			if isSweeping == false && selectedCurrency != .XMR {
//				let hasAgreedToUsageGateTerms = UserDefaults.standard.bool(
//					forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
//				)
//				if hasAgreedToUsageGateTerms == false {
//					// show alert… iff user agrees, write user has agreed to terms and proceed to branch, else bail
//					let alertController = UIAlertController(
//						title: NSLocalizedString("Important", comment: ""),
//						message: String(
//							format: NSLocalizedString(
//								"Though %@ is selected, the app will send %@. (This is not an exchange.)\n\nRate providers include %@. Neither accuracy or favorability are guaranteed. Use at your own risk.",
//								comment: "Though {fiat currency symbol} is selected, the app will send {XMR symbol}. (This is not an exchange.)\n\nRate providers include {cryptocompare domain}. Neither accuracy or favorability are guaranteed. Use at your own risk."
//							),
//							selectedCurrency.symbol,
//							CcyConversionRates.Currency.XMR.symbol,
//							SendFundsForm.rateAPI_domain // not .authority - don't need subdomain
//						),
//						preferredStyle: .alert
//					)
//					alertController.addAction(
//						UIAlertAction(
//							title: String(
//								format: NSLocalizedString("Agree and Send %@ %@", comment: "Agree and Send {amount} {XMR}"),
//								MoneroAmount.shared_doubleFormatter().string(for: amount_submittableDouble!)!,
//								CcyConversionRates.Currency.XMR.symbol
//							),
//							style: .destructive // or is red negative b/c the action is also constructive? (use .default)
//						) { (result: UIAlertAction) -> Void in
//							// must be sure to save state so alert is now not required until a DeleteEverything
//							UserDefaults.standard.set(
//								true,
//								forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
//							)
//							// and of course proceed
//							__proceedTo_disableFormAndExecute()
//						}
//					)
//					alertController.addAction(
//						UIAlertAction(
//							title: NSLocalizedString("Cancel", comment: ""),
//							style: .default
//						) { (result: UIAlertAction) -> Void in
//							// bail
//							// shouldn't need to re-enable form b/c we did alert branch/check before disabling form
//						}
//					)
//					self.navigationController!.present(alertController, animated: true, completion: nil)
//					return // early return pending alert result
//				} else {
//					let alertController = UIAlertController(
//						title: NSLocalizedString("Confirm Amount", comment: ""),
//						message: String(
//							format: NSLocalizedString(
//								"Send %@ %@?",
//								comment: "Send {amount} {XMR}?"
//							),
//							MoneroAmount.shared_doubleFormatter().string(for: amount_submittableDouble!)!,
//							CcyConversionRates.Currency.XMR.symbol
//						),
//						preferredStyle: .alert
//					)
//					alertController.addAction(
//						UIAlertAction(
//							title: NSLocalizedString("Cancel", comment: ""),
//							style: .default
//						) { (result: UIAlertAction) -> Void in
//							// bail
//							// shouldn't need to re-enable form b/c we did alert branch/check before disabling form
//						}
//					)
//					alertController.addAction(
//						UIAlertAction(
//							title: NSLocalizedString("Send", comment: ""),
//							style: .default
//						) { (result: UIAlertAction) -> Void in
//							__proceedTo_disableFormAndExecute()
//						}
//					)
//					self.navigationController!.present(alertController, animated: true, completion: nil)
//					return // early return pending alert result
//				}
//			}
			// fall through
			__proceedTo_disableFormAndExecute()
		}
		//
		// Impertives - Clearing form
		func _clearForm()
		{
			// KB: Fill in clear form stuff if necessary
			self.clearValidationMessage()
			//self.amount_fieldset.clear()
			//self.sendTo_inputView.clearAndReset()
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
			let top_yOffset: CGFloat = self.yOffsetForViewsBelowValidationMessageView
			let label_x = self.new__label_x
			let input_x = self.new__input_x
			let textField_w = self.new__textField_w
			let fullWidth_label_w = self.new__fieldLabel_w
			//
			let interSectionSpacing = UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView
			//
			// KB Additions
			let screenSize: CGRect = UIScreen.main.bounds
					
			let screenWidth = screenSize.width
			let screenHeight = screenSize.height

			self.explanation_label.frame = CGRect(
				x: label_x,
				y: top_yOffset,
				width: self.explanation_label.frame.size.width,
				height: self.explanation_label.frame.size.height
			).integral
			do { // Wallet Picker
				self.fromWallet_label.frame = CGRect(
					x: label_x,
					y: self.explanation_label.frame.origin.y + self.fromWallet_inputView.frame.size.height + interSectionSpacing,
					width: self.fromWallet_label.frame.size.width,
					height: self.fromWallet_label.frame.size.height
				).integral
				self.fromWallet_inputView.frame = CGRect(
					x: input_x,
					y: self.fromWallet_label.frame.origin.y + self.fromWallet_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAbovePushButton,
					width: textField_w,
					height: type(of: self.fromWallet_inputView).fixedHeight
				).integral
			}
			do {
				let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
				let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
				//
				self.networkFeeEstimate_label.frame = CGRect(
					x: label_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + UICommonComponents.FormFieldAccessoryMessageLabel.marginAboveLabelBelowTextInputView,
					width: 0,
					height: UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
				).integral
				self.networkFeeEstimate_label.sizeToFit() // so we can place the tooltipSpawn_buttonView next to it
				var final__frame = self.networkFeeEstimate_label.frame
				let max_w = fullWidth_label_w - 6 // or so
				if final__frame.size.width < max_w {
					final__frame.size.width = final__frame.size.width
				} else {
					final__frame.size.width = max_w
				}
				final__frame.size.height = UICommonComponents.FormFieldAccessoryMessageLabel.heightIfFixed
				self.networkFeeEstimate_label.frame = final__frame // kinda sucks to set this three times in this method. any alternative?
				//
				self.feeEstimate_tooltipSpawn_buttonView.frame = CGRect(
					x: self.networkFeeEstimate_label.frame.origin.x + self.networkFeeEstimate_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
					y: self.networkFeeEstimate_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.networkFeeEstimate_label.frame.size.height)/2,
					width: tooltipSpawn_buttonView_w,
					height: tooltipSpawn_buttonView_h
				).integral
			}
			do {
				self.inAmount_label.frame = CGRect(
					x: label_x,
					y: self.fromWallet_inputView.frame.origin.y + self.fromWallet_inputView.frame.size.height + interSectionSpacing,
					width: self.inAmount_label.frame.size.width,
					height: self.inAmount_label.frame.size.height
				).integral
				self.inAmount_label.sizeToFit() // get exact width

				self.inAmount_inputView.frame = CGRect(
					x: input_x,
					y: self.inAmount_label.frame.origin.y + self.inAmount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: UICommonComponents.FormInputField.height
				).integral
			}
			do {
				self.outAmount_label.frame = CGRect(
					x: label_x,
					y: self.inAmount_inputView.frame.origin.y + self.inAmount_inputView.frame.size.height + interSectionSpacing,
					width: self.inAmount_label.frame.size.width,
					height: self.inAmount_label.frame.size.height
				).integral
				self.outAmount_label.sizeToFit() // get exact width

				self.outAmount_inputView.frame = CGRect(
					x: input_x,
					y: self.outAmount_label.frame.origin.y + self.outAmount_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: UICommonComponents.FormInputField.height
				).integral
			}
			do {
				self.btcAddress_label.frame = CGRect(
					x: label_x,
					y: self.outAmount_inputView.frame.origin.y + self.outAmount_inputView.frame.size.height + interSectionSpacing,
					width: self.outAmount_inputView.frame.size.width,
					height: self.outAmount_inputView.frame.size.height
				).integral
				self.btcAddress_label.sizeToFit() // get exact width
				self.btcAddress_inputView.frame = CGRect(
					x: input_x,
					y: self.btcAddress_label.frame.origin.y + self.btcAddress_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
					width: textField_w,
					height: UICommonComponents.FormInputField.height
				).integral
			}
			do { // Order status validation l Label
				
				self.orderFormValidation_label.numberOfLines = 0
				self.orderFormValidation_label.lineBreakMode = NSLineBreakMode.byWordWrapping
				self.orderFormValidation_label.sizeToFit()
				self.orderFormValidation_label.frame = CGRect(
					x: label_x,
					y: self.btcAddress_inputView.frame.origin.y + self.btcAddress_inputView.frame.size.height + interSectionSpacing,
					width: self.outAmount_inputView.frame.size.width,
					height: self.outAmount_inputView.frame.size.height
				).integral
			}

			do {
//				self.resetOrder_buttonView.frame = CGRect(
//					x: input_x,
//					y: self.orderFormValidation_label.frame.origin.y + self.orderFormValidation_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginAboveLabelForUnderneathField_textInputView,
//					width: textField_w,
//					height: self.orderFormValidation_label.frame.size.height
//				).integral
				self.resetOrder_buttonView.frame = CGRect(
					x: input_x,
					y: self.inAmount_inputView.frame.origin.y,
					width: textField_w,
					height: self.orderFormValidation_label.frame.size.height
				).integral
				self.resetOrder_buttonView.isHidden = true
			}
			
//			do {
//				let previousSectionBottomView: UIView
//				do {
//					if self.manualPaymentID_inputView.isHidden == false {
//						previousSectionBottomView = self.manualPaymentID_inputView
//					} else if self.addPaymentID_buttonView.isHidden == false {
//						previousSectionBottomView = self.addPaymentID_buttonView
//					} else {
//						previousSectionBottomView = self.sendTo_inputView
//					}
//				}
//
//				self.priority_label.frame = CGRect(
//					//x: label_x,
//					x: CGFloat(-5000),
//					y: previousSectionBottomView.frame.origin.y + previousSectionBottomView.frame.size.height + interSectionSpacing,
//					width: self.priority_label.frame.size.width,
//					height: self.priority_label.frame.size.height
//				).integral
//				do {
//					let tooltipSpawn_buttonView_w: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_w
//					let tooltipSpawn_buttonView_h: CGFloat = UICommonComponents.TooltipSpawningLinkButtonView.usabilityExpanded_h
//					self.priority_tooltipSpawn_buttonView.frame = CGRect(
//						x: CGFloat(-5000),
////						x: self.priority_label.frame.origin.x + self.priority_label.frame.size.width - UICommonComponents.TooltipSpawningLinkButtonView.tooltipLabelSqueezingVisualMarginReductionConstant_x,
////
//						y: self.priority_label.frame.origin.y - (tooltipSpawn_buttonView_h - self.priority_label.frame.size.height)/2,
//						width: tooltipSpawn_buttonView_w,
//						height: tooltipSpawn_buttonView_h
//					).integral
//				}
//
//				self.priority_inputView.frame = CGRect(
//					//x: input_x,
//					x: CGFloat(-5000),
//					y: self.priority_label.frame.origin.y + self.priority_label.frame.size.height + UICommonComponents.Form.FieldLabel.marginBelowLabelAboveTextInputView,
//					width: textField_w,
//					height: self.priority_inputView.fixedHeight
//				)
//			}
			//
			let bottomMostView: UIView = self.orderFormValidation_label
			let bottomPadding: CGFloat = 18
			self.scrollableContentSizeDidChange(
				withBottomView: bottomMostView,
				bottomPadding: bottomPadding
			)
			//
			// non-scrolling:
			let buttons_y = self.view.bounds.size.height - UICommonComponents.ActionButton.wholeButtonsContainerHeight_withoutTopMargin
			//self.qrPicking_actionButtons.givenSuperview_layOut(atY: buttons_y, withMarginH: UICommonComponents.ActionButton.wholeButtonsContainer_margin_h)
		}
		override func viewDidAppear(_ animated: Bool)
		{
			let isFirstAppearance = self.hasAppearedBefore == false
			super.viewDidAppear(animated)
			// this will be called every time the view appears, including when coming back from useridle -- as such, check orderdetails is set, and if so, redirect to orderdetails page
			
			if (self.orderExists) {
				debugPrint("Order exists")
				debugPrint(self.orderExists)
				debugPrint(self.orderDetails)
				debugPrint(self.orderDetails["order_id"])
				self.navigationItem.rightBarButtonItem?.isEnabled = true
			} else {
				debugPrint("No order yet")
			}
		}
		override func viewWillDisappear(_ animated: Bool)
		{
			super.viewWillDisappear(animated)
			self.feeEstimate_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
			//self.sendTo_tooltipSpawn_buttonView.parentViewWillDisappear(animated: animated) // let it dismiss tooltips
		}
		//
		// Delegation - Amounts.InputField UITextField shunt
		func exchangeTextField(
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
			} else {
				debugPrint("pass through")
				return self.amount_fieldset.inputField.textField(
					textField,
					shouldChangeCharactersIn: range,
					replacementString: string
				)
			}
			return true
		}
	
		//
		// Delegation - Interactions
		@objc func btcAddress_changed()
		{
			debugPrint("btcAddress_changed")
			self.shouldEnableFormSubmission()
		}
		@objc func tapped_resetOrder() {
			self.orderExists = false
			self.inAmount_inputView.text = ""
			self.outAmount_inputView.text = ""
			self.btcAddress_inputView.text = ""
			self.resetOrder_buttonView.isHidden = true
			self.set_formVisiblility(isHidden: true)
			self.orderStatusViewController?.stopRemainingTimeTimer()
			self.orderStatusViewController?.stopOrderUpdateTimer()
			self.set_formVisiblility(isHidden: false)
			self.orderStatusViewController = nil
			self.reEnableForm()
		}
		
		@objc func tapped_createOrderRightBarButtonItem()
		{
			self.disableForm()
			/*
			/
			self.scrollView.resignCurrentFirstResponder()
			
			let viewController = AddContactFromContactsTabFormViewController()
			let modalViewController = UICommonComponents.NavigationControllers.SwipeableNavigationController(rootViewController: viewController)
			modalViewController.modalPresentationStyle = .formSheet
			self.navigationController!.present(modalViewController, animated: true, completion: nil)
			*/
			debugPrint("Clicked create order button")
			if (self.orderExists) {
				//let viewController = ExchangeShowOrderStatusFormViewController(selectedWallet: self.fromWallet_inputView.selectedWallet, orderDetails, orderExists: true, orderId: self.orderDetails["orderId"] as! String)
				self.navigationController!.pushViewController(self.orderStatusViewController!, animated: true)
				
			} else {
				
				if self.validOfferRetrieved {
					self.createOrder(offerId: self.offerId, out_amount: self.out_amount) {
						result in
						switch result {
							case .failure (let error):
								self.orderFormValidation_label.text = "An error was encountered: \(error)"
								self.orderFormValidation_label.sizeToFit()
								let bottomPadding: CGFloat = 18
								self.scrollableContentSizeDidChange(
									withBottomView: self.orderFormValidation_label,
									bottomPadding: bottomPadding
								)
								self.reEnableForm()
								debugPrint(error)
							case .success(let value):
								debugPrint(value)
								self.orderDetails = value
								self.orderExists = true
								// handle Unexpectedly found nil while unwrapping an Optional value
								let viewController = ExchangeShowOrderStatusFormViewController(selectedWallet: self.fromWallet_inputView.selectedWallet, orderDetails: value, orderId: value["order_id"] as! String)
								self.orderStatusViewController = viewController
								self.navigationController!.pushViewController(viewController, animated: true)
								self.set_formVisiblility(isHidden: true)
								self.resetOrder_buttonView.isHidden = false
								
								//self.scrollView.addSubview(viewController.view)
								
								//self.navigationItem.rightBarButtonItem = nil
							}
						}
					} else {
						self.orderFormValidation_label.text = "Please enter a valid exchange amount"
					}
			}
		}
		@objc func addPaymentID_tapped()
		{
			self.set_addPaymentID_buttonView(isHidden: true)
			self.set_manualPaymentIDField(isHidden: false)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
			{ [unowned self] in
				self.manualPaymentID_inputView.becomeFirstResponder()
			}
		}
		@objc func tapped_generatePaymentID()
		{
			self.manualPaymentID_inputView.text = MyMoneroCore_ObjCpp.new_short_plain_paymentID()
		}
		//
		// Delegation - URL picking (also used by QR picking)
		func ___shared_initialResetFormFor_didPick()
		{
			self.clearValidationMessage() // in case there was a parsing err etc displaying
//			self._clearForm() // specifically not clearing the form - b/c we want to allow priority and even amount to remain set ... dest addr/contact will always be set by a request URI/QR ..
			//
			//self.sendTo_inputView.cancelAny_oaResolverRequestMaker()
		}
		func __shared_didPick(possibleRequestURIStringForAutofill possibleRequestURIString: String)
		{
			self.___shared_initialResetFormFor_didPick()
			//
			let (err_str, optl_requestPayload) = MoneroUtils.URIs.Requests.new_parsedRequest(
				fromPossibleURIOrMoneroOrOAAddressString: possibleRequestURIString
			)
			if err_str != nil {
				self.set(
					validationMessage: String(format:
						NSLocalizedString("Unable to use the result of decoding that QR code: %@", comment: "Unable to use the result of decoding that QR code: {error}"),
						err_str!
					),
					wantsXButton: true
				)
				return
			}
			self.__shared_havingClearedForm_didPick(requestPayload: optl_requestPayload!)
		}
		func __shared_didPick(confirmedRequestURIStringForAutofill requestURIString: String)
		{
			self.___shared_initialResetFormFor_didPick()
			//
			let (err_str, optl_requestPayload) = MoneroUtils.URIs.Requests.new_parsedRequest(
				fromPossibleURIOrMoneroOrOAAddressString: requestURIString
			)
			if err_str != nil {
				self.set(
					validationMessage: String(format: NSLocalizedString("Unable to decode that URL: %@", comment: "Unable to decode that URL: {error}"), err_str!),
					wantsXButton: true
				)
				return
			}
			self.__shared_havingClearedForm_didPick(requestPayload: optl_requestPayload!)
		}
		func __shared_havingClearedForm_didPick(requestPayload: MoneroUtils.URIs.Requests.ParsedRequest)
		{
//			var currencyToSelect: CcyConversionRates.Currency?
//			if let amountCurrencySymbol = requestPayload.amountCurrency,
//				amountCurrencySymbol != ""
//			{
//				let currency = CcyConversionRates.Currency(
//					rawValue: amountCurrencySymbol
//				)
//				if currency == nil {
//					self.set(
//						validationMessage: NSLocalizedString("Unrecognized currency on funds request", comment: ""),
//						wantsXButton: true
//					)
//					return
//				}
//				currencyToSelect = currency!
//			}
//			var didSetAmountFromRequest = false // to be finalized as follows…
//			// as long as currency was valid…
//			if let amountString = requestPayload.amount, amountString != "" {
//				didSetAmountFromRequest = true
//				self.amount_fieldset.inputField.text = amountString
//				self.amount_fieldset.configure_effectiveMoneroAmountLabel() // b/c we just manually changed the text - would be nice to have an abstraction to do all this :P
//			}
//			if currencyToSelect != nil {
//				if (self.amount_fieldset.inputField.text == nil || self.amount_fieldset.inputField.text == "")
//					|| didSetAmountFromRequest { // so either the ccy and amount were on the request OR there was a ccy but the amount field was left empty by the user, i.e. we can assume it's ok to modify the ccy since there was one on the request
//					self.amount_fieldset.currencyPickerButton.set(
//						selectedCurrency: currencyToSelect!, // permissable to fall back to XMR here if no ccy present on the request
//						skipSettingOnPickerView: false
//					)
//				}
//			} else {
//				// otherwise, just keep it as it is …… because if they set it to, e.g. CAD, and there's no ccy on the request, then they might accidentally send the same numerical value in XMR despite having wanted it to be in CAD
//			}
//			do {
//				let target_address = requestPayload.address
//				assert(target_address != "") // b/c it should have been caught as a validation err on New_ParsedRequest_FromURIString
//				let payment_id_orNil = requestPayload.paymentID
//				var foundContact: Contact?
//				do {
//					let records = ContactsListController.shared.records
//					for (_, record) in records.enumerated() {
//						let contact = record as! Contact
//						if contact.address == target_address || contact.cached_OAResolved_XMR_address == target_address {
//							// so this request's address corresponds with this contact…
//							// how does the payment id match up?
//							/*
//							* Commented until we figure out this payment ID situation.
//							* The problem is that the person who uses this request to send
//							* funds (i.e. the user here) may have the target of the request
//							* in their Address Book (the req creator) but the request recipient
//							* would have in their address book a /different/ payment_id for the target
//							* than the payment_id in the contact used by the creator to generate
//							* this request.
//
//							* One proposed solution is to give contacts a "ReceiveFrom-With" and "SendTo-With"
//							* payment_id. Then when a receiver loads a request (which would have a payment_id of
//							* the creator's receiver contact's version of "ReceiveFrom-With"), we find the contact
//							* (by address/cachedaddr) and if it doesn't yet have a "SendTo-With" payment_id,
//							* we show it as 'detected', and set its value to that of ReceiveFrom-With from the request
//							* if they hit send. This way users won't have to send each other their pids.
//
//							* Currently, this is made to work below by not looking at the contact itself for payment
//							* ID match, but just using the payment ID on the request itself, if any.
//
//							if (payment_id_orNull) { // request has pid
//							if (contact.payment_id && typeof contact.payment_id !== 'undefined') { // contact has pid
//							if (contact.payment_id !== payment_id_orNull) {
//							console.log("contact has same address as request but different payment id!")
//							continue // TODO (?) keep this continue? or allow and somehow use the pid from the request?
//							} else {
//							// contact has same pid as request pid
//							console.log("contact has same pid as request pid")
//							}
//							} else { // contact has no pid
//							console.log("request pid exists but contact has no request pid")
//							}
//							} else { // request has no pid
//							if (contact.payment_id && typeof contact.payment_id !== 'undefined') { // contact has pid
//							console.log("contact has pid but request has no pid")
//							} else { // contact has no pid
//							console.log("neither request nor contact have pid")
//							// this is fine - we can use this contact
//							}
//							}
//							*/
//							foundContact = contact
//							break
//						}
//					}
//					if foundContact != nil {
//						self.sendTo_inputView.pick(
//							contact: foundContact!,
//							skipOAResolve: true, // special case
//							useContactPaymentID: false // but we're not going to show the PID stored on the contact!
//						)
//					} else { // we have an addr but no contact
//						if let _ = self.sendTo_inputView.selectedContact {
//							self.sendTo_inputView.unpickSelectedContact_andRedisplayInputField(
//								skipFocusingInputField: true // do NOT focus input
//							)
//						}
//						self.sendTo_inputView.setInputField(text: target_address) // we must use this method instead of just going _inputView.inputField.text = ... b/c that would not alone send the event .editingChanged and would cause e.g. .hasValidTextInput_moneroAddress to be stale
//					}
//				}
//				// and no matter what, display payment id from request, if present
//				if payment_id_orNil != nil { // but display it as a 'detected' pid which we can pick up on submit
//					self.hideAndClear_manualPaymentIDField()
//					self.set_addPaymentID_buttonView(isHidden: true) // hide
//					self.sendTo_inputView._display(resolved_paymentID: payment_id_orNil!) // NOTE: kind of bad to use these private methods like this - TODO: establish a proper interface for doing this!
//				} else {
//					self.sendTo_inputView._hide_resolved_paymentID() // jic // NOTE: kind of bad to use these private methods like this - TODO: establish a proper interface for doing this!
//					if self.manualPaymentID_inputView.text == nil || self.manualPaymentID_inputView.text!.count == 0 {
//						// if no pid already in the manual pid field, just be sure to reset the form to its proper state
//						self.hideAndClear_manualPaymentIDField()
//						self.set_addPaymentID_buttonView(isHidden: false) // show
//					}
//				}
//			}
//			self.set_isFormSubmittable_needsUpdate() // now that we've updated values
		}
		//
		// Protocol - DeleteEverythingRegistrant
		func passwordController_DeleteEverything() -> String?
		{
			DispatchQueue.main.async
			{ [unowned self] in	
				self._clearForm()
				//self.qrPicking_actionButtons.teardownAnyPickers()
				// TODO/NOTE: This actually may be much better implemented as a property on the Settings controller as in the JS app
//				do { // special:
//					UserDefaults.standard.removeObject(
//						forKey: UsageGateState_PlainStorage_Keys.hasAgreedToTermsOfCalculatedEffectiveMoneroAmount.key
//					)
//				}
//				//
				// should already have popped to root thanks to root tab bar vc
			}
			//
			return nil // no error
		}
		//
		// Delegation - Notifications
		@objc func PasswordController_willDeconstructBootedStateAndClearPassword()
		{
			self._clearForm()
			//self.qrPicking_actionButtons.teardownAnyPickers()
			//
			// should already have popped to root thanks to root tab bar vc
		}
		@objc func PasswordController_didDeconstructBootedStateAndClearPassword()
		{
			
		}
		@objc func URLOpening_saysTimeToHandleReceivedMoneroURL(_ notification: Notification)
		{
			let userInfo = notification.userInfo!
			let url = userInfo[URLOpening.NotificationUserInfoKeys.url.key] as! URL
			assert(self.isFormEnabled)
			// obviously, we can only do the following if the user has already unlocked the apps
			do { // dismissing these b/c of checks in __shared_isAllowedToPerformDropOrURLOpeningOps
				self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // if any
				self.navigationController?.popToRootViewController(animated: false) // if any
			}
			self.__shared_didPick(confirmedRequestURIStringForAutofill: url.absoluteString)
		}
		//
		@objc func WalletAppContactActionsCoordinator_didTrigger_sendFundsToContact(_ notification: Notification)
		{
			
//			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
//			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
//			//
//			if self.isFormEnabled == false {
//				DDLog.Warn("SendFunds", "Triggered send funds from contact while submit btn disabled. Beep.")
//				// TODO: is a .failure haptic appropriate here?
//				// TODO: mayyybe alert tx in progress
//				return
//			}
//			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
//			let contact = notification.userInfo![WalletAppContactActionsCoordinator.NotificationUserInfoKeys.contact.key] as! Contact
//			self.sendTo_inputView.pick(contact: contact) // simulate user picking the contact
		}
		@objc func WalletAppWalletActionsCoordinator_didTrigger_sendFundsFromWallet(_ notification: Notification)
		{
			self.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil) // whether we should force-dismiss these (create new contact) is debatable…
			self.navigationController?.popToRootViewController(animated: false) // now pop pushed stack views - essential for the case they're viewing a transaction
			//
			if self.isFormEnabled == false {
				DDLog.Warn("SendFunds", "Triggered send funds from wallet while submit btn disabled. Beep.")
				// TODO: is a .failure haptic appropriate here?
				// TODO: mayyybe alert tx in progress
				return
			}
			self._clearForm() // figure that since this method is called when user is trying to initiate a new request we should clear the form
			let wallet = notification.userInfo![WalletAppWalletActionsCoordinator.NotificationUserInfoKeys.wallet.key] as! Wallet
			self.fromWallet_inputView.set(selectedWallet: wallet)
		}
		//
		@objc func CcyConversionRates_didUpdateAvailabilityOfRates()
		{
			self.configure_networkFeeEstimate_label() // the amount field takes care of observing this for itself but the estimate label doesn't…… could be factored……
			//self.configure_amountInputTextGivenMaxToggledState() // if necessary
		}
		@objc func SettingsController__NotificationNames_Changed__displayCurrencySymbol()
		{
			self.configure_networkFeeEstimate_label()
			//self.configure_amountInputTextGivenMaxToggledState()
		}
	}
}
