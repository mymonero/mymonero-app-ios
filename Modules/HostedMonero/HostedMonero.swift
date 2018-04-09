//
//  HostedMoneroAPIClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
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
import Foundation
import Alamofire
//
struct HostedMoneroAPIClient_Parsing
{
	struct ParsedResult_TXTRecords
	{
		let records: [String]
		let dnssec_used: Bool
		let secured: Bool
		let dnssec_fail_reason: String?
	}
	struct ParsedResult_AddressInfo
	{
		let totalReceived: MoneroAmount
		let totalSent: MoneroAmount
		let lockedBalance: MoneroAmount
		//
		let account_scanned_tx_height: Int
		let account_scanned_block_height: Int
		let account_scan_start_height: Int
		let transaction_height: Int
		let blockchain_height: Int
		//
		let spentOutputs: [MoneroSpentOutputDescription] // these have a different format than MoneroOutputDescriptions (whose type's name needs to be made more precise)
		//
		let xmrToCcyRatesByCcy: [CcyConversionRates.Currency: Double]
	}
	struct ParsedResult_AddressTransactions
	{
		let account_scanned_height: Int
		let account_scanned_block_height: Int
		let account_scan_start_height: Int
		let transaction_height: Int
		let blockchain_height: Int
		//
		let transactions: [MoneroHistoricalTransactionRecord]
	}
	struct ParsedResult_UnspentOuts
	{
		let unspentOutputs: [MoneroOutputDescription]
		let unusedOutputs: [MoneroOutputDescription]
	}
	struct ParsedResult_RandomOuts
	{
		let amount_outs: [MoneroRandomAmountAndOutputs]
	}
	struct ParsedResult_ImportRequestInfoAndStatus
	{
		let payment_id: MoneroPaymentID
		let payment_address: MoneroAddress
		let import_fee: MoneroAmount
		let feeReceiptStatus: String?
	}
}
//
enum HostedMoneroAPI_Endpoint: String
{
	case LogIn = "login"
	case AddressInfo = "get_address_info"
	case AddressTransactions = "get_address_txs"
	case UnspentOuts = "get_unspent_outs"
	case RandomOuts = "get_random_outs"
	case TXTRecords = "get_txt_records"
	case SubmitSerializedSignedTransaction = "submit_raw_tx"
	case ImportRequestInfoAndStatus = "import_wallet_request"
}
//
struct HostedMoneroAPIClient_HostConfig
{
	// currently not in use
//	static let hostingServiceFee_depositAddress = "49VNLa9K5ecJo13bwKYt5HCmA8GkgLwpyFjgGKG6qmp8dqoXww8TKPU2PJaLfAAtoZGgtHfJ1nYY8G2YaewycB4f72yFT6u"
	static let hostingServiceFee_txFeeRatioOfNetworkFee = 0.5 // Service fee relative to tx fee (0.5 => 50%)
	//
	static func HostingServiceChargeForTransaction(with networkFee: MoneroAmount) -> MoneroAmount
	{
		let feeRatioReciprocalInteger = MoneroAmount(UInt(1.0/hostingServiceFee_txFeeRatioOfNetworkFee)) // instead of just *, because ratio is not an integer
		let amount = networkFee / feeRatioReciprocalInteger
		return amount
	}
}
//
final class HostedMoneroAPIClient
{
	//
	// Static - Singleton
	static let shared = HostedMoneroAPIClient()
	//
	// Static - Constants
	static let apiAddress_scheme = "https"
	static let mymonero_apiAddress_authority = "api.mymonero.com:8443"
	//
	static let mymonero_importFeeSubmissionTarget_openAliasAddress = "import.mymonero.com" // possibly exists a better home for this
	//
	var final_apiAddress_authority: String { // authority means [subdomain.]host.…[:…]
		assert(SettingsController.shared.hasBooted)
		let settings_authorityValue = SettingsController.shared.specificAPIAddressURLAuthority
		if settings_authorityValue == nil {
			return type(of: self).mymonero_apiAddress_authority
		}
		if settings_authorityValue == "" { // NOTE: This should not technically be here. See SettingsController's set(valuesByDictKey:)'s failed attempt at nil detection in normalizing "" to nil
			return type(of: self).mymonero_apiAddress_authority
		}
		assert(settings_authorityValue != "")
	 	return settings_authorityValue!
	}
	//
	// Types
	typealias RequestHandle = Alamofire.DataRequest
	//
	// Instance - Properties
	var manager: SessionManager!
	//
	// Lifecycle - Singleton Init
	private init()
	{
		setup()
	}
	func setup()
	{
		self.initializeManagerWithFinalServerAuthority() // TODO: defer this until we have booted Settings for extra rigor
		self.startObserving()
	}
	func startObserving()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(SettingsController__NotificationNames_Changed__specificAPIAddressURLAuthority),
			name: SettingsController.NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName,
			object: nil
		)
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.teardown()
	}
	func teardown()
	{
		self.stopObserving()
	}
	func stopObserving()
	{
		NotificationCenter.default.removeObserver(self, name: SettingsController.NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName, object: nil)
	}
	//
	// Runtime - Configuration - Manager
	func initializeManagerWithFinalServerAuthority()
	{
		let serverTrustPolicies_byDomain: [String: ServerTrustPolicy] =
		[
			self.final_apiAddress_authority: .pinCertificates(
				certificates: ServerTrustPolicy.certificates(),
				validateCertificateChain: true,
				validateHost: true
			)
		]
		self.manager = SessionManager(
			configuration: URLSessionConfiguration.default,
			serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies_byDomain)
		)
	}
	//
	// Internal - Accessors - Shared
	private func _new_parameters_forWalletRequest(
		address: MoneroAddress,
		view_key__private: MoneroKey
	) -> [String: Any]
	{
		return [
			"address": address,
			"view_key": view_key__private
		]
	}
	//
	// Internal - Imperatives - Shared
	private func _shared_onMain_callBackFromRequest<T>(
		_ err_str: String?,
		_ result: T?,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: T?
		) -> Void
	)
	{
		if err_str != nil {
			DDLog.Error("HostedMonero", "\(err_str!)")
		}
		if Thread.isMainThread { // minor 
			fn(err_str, result)
		} else {
			DispatchQueue.main.async
			{
				fn(err_str, result)
			}
		}
	}
	//
	// Login
	@discardableResult
	func LogIn(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ isANewAddressToServer: Bool?
		) -> Void
	) -> RequestHandle?
	{
		var parameters = self._new_parameters_forWalletRequest(
			address: address,
			view_key__private: view_key__private
		)
		parameters["create_account"] = true
		//
		let endpoint = HostedMoneroAPI_Endpoint.LogIn
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			let response_jsonDict = response_jsonDict!
			let isNewAddressToServer = response_jsonDict["new_address"] as! Bool
			self._shared_onMain_callBackFromRequest(err_str, isNewAddressToServer, fn)
		}
		return requestHandle
	}
	//
	// Wallet info / sync
	@discardableResult
	func AddressInfo(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_AddressInfo?
		) -> Void
	) -> RequestHandle?
	{
		let parameters = self._new_parameters_forWalletRequest(
			address: address,
			view_key__private: view_key__private
		)
		let endpoint = HostedMoneroAPI_Endpoint.AddressInfo
		let requestHandle = self._request(endpoint, parameters)
		{ [unowned self] (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			let response_jsonDict = response_jsonDict!
			MyMoneroCore.shared.Parsed_AddressInfo(
				response_jsonDict: response_jsonDict,
				address: address,
				view_key__private: view_key__private,
				spend_key__public: spend_key__public,
				spend_key__private: spend_key__private
			)
			{ (err_str, result) in
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}

		}
		return requestHandle
	}
	@discardableResult
	func AddressTransactions(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_AddressTransactions?
		) -> Void
	) -> RequestHandle?
	{
		let parameters = self._new_parameters_forWalletRequest(
			address: address,
			view_key__private: view_key__private
		)
		//
		let endpoint = HostedMoneroAPI_Endpoint.AddressTransactions
		let requestHandle = self._request(endpoint, parameters)
		{ [unowned self] (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			let response_jsonDict = response_jsonDict!
			MyMoneroCore.shared.Parsed_AddressTransactions(
				response_jsonDict: response_jsonDict,
				address: address,
				view_key__private: view_key__private,
				spend_key__public: spend_key__public,
				spend_key__private: spend_key__private
			)
			{ (err_str, result) in
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}
		}
		return requestHandle
	}
	//
	// Import request info
	func ImportRequestInfoAndStatus(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_ImportRequestInfoAndStatus?
		) -> Void
	) -> RequestHandle?
	{
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private
		]
		let endpoint = HostedMoneroAPI_Endpoint.ImportRequestInfoAndStatus
		let requestHandle = self._request(endpoint, parameters)
		{ [unowned self] (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			let result = HostedMoneroAPIClient_Parsing.ParsedResult_ImportRequestInfoAndStatus(
				payment_id: response_jsonDict!["payment_id"] as! MoneroPaymentID,
				payment_address: response_jsonDict!["payment_address"] as! MoneroAddress,
				import_fee: MoneroAmount(response_jsonDict!["import_fee"] as! String)!,
				feeReceiptStatus: response_jsonDict!["status"] as? String
			)
			self._shared_onMain_callBackFromRequest(err_str, result, fn)
		}
		return requestHandle
	}
	//
	// Sending funds
	@discardableResult
	func UnspentOuts(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts?
		) -> Void
	) -> RequestHandle?
	{
		let mixinSize = MyMoneroCore.fixedMixin
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private,
			"amount": "0",
			"mixin": mixinSize,
			"use_dust": mixinSize == 0, // Use dust outputs only when we are using no mixins
			"dust_threshold": String(MoneroConstants.dustThreshold, radix: 10)
		]
		let endpoint = HostedMoneroAPI_Endpoint.UnspentOuts
		let requestHandle = self._request(endpoint, parameters)
		{ [unowned self] (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			MyMoneroCore.shared.Parsed_UnspentOuts(
				response_jsonDict: response_jsonDict!,
				address: address,
				view_key__private: view_key__private,
				spend_key__public: spend_key__public,
				spend_key__private: spend_key__private
			)
			{ (err_str, result) in
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}
		}
		return requestHandle
	}
	func RandomOuts(
		using_outs: [MoneroOutputDescription],
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts?
		) -> Void
	) -> RequestHandle?
	{
		let mixinSize = MyMoneroCore.fixedMixin
		if (mixinSize < 0) {
			fn("Invalid mixin - must be >= 0", nil)
			return nil
		}
		//
		var amounts = [String]()
		for (_, using_out_desc) in using_outs.enumerated() {
			amounts.append(using_out_desc.rct != nil ? "0" : String(using_out_desc.amount))
		}
		let parameters: [String: Any] =
		[
			"amounts": amounts,
			"count": mixinSize + 1 // Add one to mixin so we can skip real output key if necessary
		]
		let endpoint = HostedMoneroAPI_Endpoint.RandomOuts
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				self._shared_onMain_callBackFromRequest(err_str, nil, fn)
				return
			}
			let response_jsonDict = response_jsonDict!
			let amount_outs = response_jsonDict["amount_outs"] as! [[String: Any]]
			//
			var final_amount_outs: [MoneroRandomAmountAndOutputs] = []
			do { // finalize
				for (_, dict) in amount_outs.enumerated() {
					let amountAndOutputs = MoneroRandomAmountAndOutputs.new(withCoreParsed_jsonDict: dict)
					final_amount_outs.append(amountAndOutputs)
				}
			}
			let result = HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts(
				amount_outs: final_amount_outs
			)
			self._shared_onMain_callBackFromRequest(nil, result, fn)
		}
		return requestHandle
	}
	func SubmitSerializedSignedTransaction(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		serializedSignedTx: MoneroSerializedSignedTransaction,
		_ fn: @escaping (
			_ err_str: String?, // if nil, succeeded
			_ nilResult: Any? // merely for callback conformance (janky :\) - disregard arg
		) -> Void
	) -> RequestHandle?
	{
		#if DEBUG
			#if MOCK_SUCCESSOFTXSUBMISSION
				DDLog.Warn("HostedMonero", "Merely returning mocked success response instead of actually submitting transaction to the server.")
				self._shared_onMain_callBackFromRequest(nil, nil, fn)
				return nil
			#endif
		#endif
		DDLog.Do("HostedMonero", "Submitting transaction…")
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private,
			"tx": serializedSignedTx
		]
		let endpoint = HostedMoneroAPI_Endpoint.SubmitSerializedSignedTransaction
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			self._shared_onMain_callBackFromRequest(err_str, nil, fn)
		}
		return requestHandle
	}
	//
	// Private - Runtime - Imperatives - Requests - Shared
	@discardableResult
	open func _request(
		_ endpoint: HostedMoneroAPI_Endpoint,
		_ parameters: Alamofire.Parameters,
		_ fn: @escaping (
			_ err_str: String?,
			_ response_data: Data?,
			_ response_jsonDict: [String: Any]?
		) -> Void
	) -> RequestHandle?
	{
		let headers: HTTPHeaders =
		[
			"Accept": "application/json",
			"Content-Type": "application/json",
		]
		let url = "\(type(of: self).apiAddress_scheme)://\(self.final_apiAddress_authority)/\(endpoint.rawValue)"
//		DDLog.Net("HostedMonero", "\(url)")
		var final_parameters = parameters
		do { // client metadata
			if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
				final_parameters["app_name"] = value
			} else {
				DDLog.Warn("HostedMonero", "Bundle.main missing CFBundleDisplayName")
			}
			if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
				final_parameters["app_version"] = value
			} else {
				DDLog.Warn("HostedMonero", "Bundle.main missing CFBundleShortVersionString")
			}
			//
			final_parameters["app_system_version"] = UIDevice.current.systemVersion
			final_parameters["app_system_name"] = UIDevice.current.systemName
			final_parameters["app_device_model"] = UIDevice.current.model
		}
		let requestHandle = self.manager.request(
			url,
			method: .post,
			parameters: final_parameters,
			encoding: JSONEncoding.default,
			headers: headers
			// these sorts of things shouldn't be necessary but bit us in JS/web
//			, useXDR: true, // CORS
//			withCredentials: true // CORS
		).validate(statusCode: 200..<300).validate(contentType: ["application/json"])
		.responseJSON
		{ response in
			let statusCode = response.response?.statusCode ?? -1
			switch response.result
			{
				case .failure(let error):
					print(error)
					DDLog.Error("HostedMonero", "\(url) \(statusCode)")
					fn(error.localizedDescription, nil, nil) // localized description ok here?
					return
				case .success:
//					DDLog.Done("HostedMonero", "\(url) \(statusCode)")
					break
			}
			guard let result_value = response.result.value else {
				fn("Unable to find data in response from server.", nil, nil)
				return
			}
			guard let JSON = result_value as? [String: Any] else {
				fn("Unable to find JSON in response from server.", nil, nil)
				return
			}
			fn(nil, response.data, JSON)
		}
		//
		return requestHandle
	}
	//
	// Delegation - Notifications - Custom API address change
	@objc func SettingsController__NotificationNames_Changed__specificAPIAddressURLAuthority()
	{
		self.initializeManagerWithFinalServerAuthority()
	}
}
//
extension MyMoneroCoreJS // for Parsing
{
	func Parsed_AddressInfo(
		response_jsonDict: [String: Any],
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_AddressInfo?
		) -> Void
	)
	{
		let json_String = __jsonStringForArg(fromJSONDict: response_jsonDict)
		let args =
		[
			json_String,
			address.jsRepresentationString,
			view_key__private.jsRepresentationString,
			spend_key__public.jsRepresentationString,
			spend_key__private.jsRepresentationString
		]
		self._callSync(.responseParser, "Parsed_AddressInfo__sync", args)
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let returnValuesByKey = any as! [String: Any]
			//
			func __new_MoneroAmount(fromOptlAmountStringAtKeyNamed keyName: String) -> MoneroAmount
			{
				var amount: MoneroAmount?
				if let stringValue = returnValuesByKey[keyName] as? String {
					// ^-- is `as? String` sufficient to check for NSNull/null from JS?
					if stringValue != "" { // not sure if we really need this
						amount = MoneroAmount(stringValue)
					}
				}
				return amount ?? MoneroAmount(0)
			}
			//
			let totalReceived_Amount: MoneroAmount = __new_MoneroAmount(
				fromOptlAmountStringAtKeyNamed: "total_received_String"
			)
			let totalSent_Amount: MoneroAmount = __new_MoneroAmount(
				fromOptlAmountStringAtKeyNamed: "total_sent_String"
			)
			let lockedBalance_Amount: MoneroAmount = __new_MoneroAmount(
				fromOptlAmountStringAtKeyNamed: "locked_balance_String"
			)
			//
			let account_scanned_tx_height = returnValuesByKey["account_scanned_tx_height"] as? Int
			let account_scanned_block_height = returnValuesByKey["account_scanned_block_height"] as? Int
			let account_scan_start_height = returnValuesByKey["account_scan_start_height"] as? Int
			let transaction_height = returnValuesByKey["transaction_height"] as? Int
			let blockchain_height = returnValuesByKey["blockchain_height"] as? Int
			//
			var final_spentOutputs: [MoneroSpentOutputDescription] = []
			do { // finalize
				if let spentOutputs = returnValuesByKey["spent_outputs"] as? [[String: Any]] {
					for (_, dict) in spentOutputs.enumerated() {
						let outputDescription = MoneroSpentOutputDescription.new(withCoreParsed_jsonDict: dict)
						final_spentOutputs.append(outputDescription)
					}
				}
			}
			//
			var final_xmrToCcyRatesByCcy: [CcyConversionRates.Currency: Double] = [:]
			do {
				if let xmrToCcyRatesByCcySymbol = returnValuesByKey["ratesBySymbol"] as? [String: Double] {
					for (_, keyAndValueTuple) in xmrToCcyRatesByCcySymbol.enumerated() {
						let ccySymbol = keyAndValueTuple.key
						let xmrToCcyRate = keyAndValueTuple.value
						guard let ccy = CcyConversionRates.Currency(rawValue: ccySymbol) else {
							DDLog.Warn("HostedMoneroAPIClient", "Unrecognized currency \(ccySymbol) in rates matrix")
							continue
						}
						final_xmrToCcyRatesByCcy[ccy] = xmrToCcyRate
					}
				}
			}
			//
			let result = HostedMoneroAPIClient_Parsing.ParsedResult_AddressInfo(
				totalReceived: totalReceived_Amount,
				totalSent: totalSent_Amount,
				lockedBalance: lockedBalance_Amount,
				//
				account_scanned_tx_height: account_scanned_tx_height ?? 0,
				account_scanned_block_height: account_scanned_block_height ?? 0,
				account_scan_start_height: account_scan_start_height ?? 0,
				transaction_height: transaction_height ?? 0,
				blockchain_height: blockchain_height ?? 0,
				//
				spentOutputs: final_spentOutputs,
				//
				xmrToCcyRatesByCcy: final_xmrToCcyRatesByCcy
			)
			fn(nil, result)
		}
	}
	func Parsed_AddressTransactions(
		response_jsonDict: [String: Any],
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_AddressTransactions?
		) -> Void
	)
	{
		let json_String = __jsonStringForArg(fromJSONDict: response_jsonDict)
		let args =
			[
				json_String,
				address.jsRepresentationString,
				view_key__private.jsRepresentationString,
				spend_key__public.jsRepresentationString,
				spend_key__private.jsRepresentationString
		]
		self._callSync(.responseParser, "Parsed_AddressTransactions__sync", args)
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let returnValuesByKey = any as! [String: Any]
			//
			let account_scanned_height = returnValuesByKey["account_scanned_height"] as? Int
			let account_scanned_block_height = returnValuesByKey["account_scanned_block_height"] as? Int
			let account_scan_start_height = returnValuesByKey["account_scan_start_height"] as? Int
			let transaction_height = returnValuesByKey["transaction_height"] as? Int
			let blockchain_height = returnValuesByKey["blockchain_height"] as? Int
			//
			var transactions: [MoneroHistoricalTransactionRecord] = []
			do {
				if let serialized_transactions = returnValuesByKey["serialized_transactions"] as? [[String: Any]] {
					for (_, dict) in serialized_transactions.enumerated() {
						let transactionRecord = MoneroHistoricalTransactionRecord.new(
							withCoreParsed_jsonDict: dict,
							wallet__blockchainHeight: blockchain_height! // if we have txs to parse, I think we can assume height != 0
						)
						transactions.append(transactionRecord)
					}
				}
			}
			let result = HostedMoneroAPIClient_Parsing.ParsedResult_AddressTransactions(
				account_scanned_height: account_scanned_height ?? 0,
				account_scanned_block_height: account_scanned_block_height ?? 0,
				account_scan_start_height: account_scan_start_height ?? 0,
				transaction_height: transaction_height ?? 0,
				blockchain_height: blockchain_height ?? 0,
				//
				transactions: transactions
			)
			fn(nil, result)
		}
	}
	func Parsed_UnspentOuts(
		response_jsonDict: [String: Any],
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts?
		) -> Void
	)
	{
		let json_String = __jsonStringForArg(fromJSONDict: response_jsonDict)
		let args =
		[
			json_String,
			address.jsRepresentationString,
			view_key__private.jsRepresentationString,
			spend_key__public.jsRepresentationString,
			spend_key__private.jsRepresentationString
		]
		self._callSync(.responseParser, "Parsed_UnspentOuts__sync", args)
		{ (err_str, any) in
			if let err_str = err_str {
				fn(err_str, nil)
				return
			}
			let returnValuesByKey = any as! [String: Any]
			let unusedOuts = returnValuesByKey["unusedOuts"] as! [[String: Any]]
			let unspentOutputs = returnValuesByKey["unspentOutputs"] as! [[String: Any]]
			//
			var final_unusedOutputs: [MoneroOutputDescription] = []
			do { // finalize
				for (_, dict) in unusedOuts.enumerated() {
					let outputDescription = MoneroOutputDescription.new(withCoreParsed_jsonDict: dict)
					final_unusedOutputs.append(outputDescription)
				}
			}
			var final_unspentOutputs: [MoneroOutputDescription] = []
			do { // finalize
				for (_, dict) in unspentOutputs.enumerated() {
					let outputDescription = MoneroOutputDescription.new(withCoreParsed_jsonDict: dict)
					final_unspentOutputs.append(outputDescription)
				}
			}
			let result = HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts(
				unspentOutputs: final_unspentOutputs,
				unusedOutputs: final_unusedOutputs
			)
			fn(nil, result)
		}
	}
}
