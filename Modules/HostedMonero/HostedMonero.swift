//
//  HostedMonero.swift
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
struct HostedMonero {}
extension HostedMonero
{
	struct ParsedResult_AddressInfo
	{
		let totalReceived: MoneroAmount
		let totalSent: MoneroAmount
		let lockedBalance: MoneroAmount
		//
		let account_scanned_height: UInt64
		let account_scanned_block_height: UInt64
		let account_scan_start_height: UInt64
		let transaction_height: UInt64
		let blockchain_height: UInt64
		//
		let xmrToCcyRatesByCcy: [CcyConversionRates.Currency: Double]
		//
		static func new(
			withLightWallet3Wrapper wrapper: LightWallet3Wrapper,
			response_jsonDict: [String: Any]
		) -> (
			err_str: String?,
			result: ParsedResult_AddressInfo?
		) {
			let total_received = MoneroAmount("\(wrapper.total_received() as UInt64)")!
			let locked_balance = MoneroAmount("\(wrapper.locked_balance() as UInt64)")!
			let total_sent = MoneroAmount("\(wrapper.total_sent() as UInt64)")!
			//
			let account_scanned_height = wrapper.scanned_height() as UInt64
			let account_scanned_block_height = wrapper.scanned_block_height() as UInt64
			let account_scan_start_height = wrapper.scan_start_height() as UInt64
			let transaction_height = wrapper.transaction_height() as UInt64
			let blockchain_height = wrapper.blockchain_height() as UInt64
			//
			let xmrToCcyRatesByCcySymbol = response_jsonDict["rates"] as? [String: Double] ?? [String: Double]() // jic it's not there
			var final_xmrToCcyRatesByCcy: [CcyConversionRates.Currency: Double] = [:]
			for (_, keyAndValueTuple) in xmrToCcyRatesByCcySymbol.enumerated() {
				let ccySymbol = keyAndValueTuple.key
				let xmrToCcyRate = keyAndValueTuple.value
				guard let ccy = CcyConversionRates.Currency(rawValue: ccySymbol) else {
					DDLog.Warn("HostedMonero.APIClient", "Unrecognized currency \(ccySymbol) in rates matrix")
					continue
				}
				final_xmrToCcyRatesByCcy[ccy] = xmrToCcyRate
			}
			//
			let result = ParsedResult_AddressInfo(
				totalReceived: total_received,
				totalSent: total_sent,
				lockedBalance: locked_balance,
				//
				account_scanned_height: account_scanned_height,
				account_scanned_block_height: account_scanned_block_height,
				account_scan_start_height: account_scan_start_height,
				transaction_height: transaction_height,
				blockchain_height: blockchain_height,
				//
				xmrToCcyRatesByCcy: final_xmrToCcyRatesByCcy
			)
			return (nil, result)
		}
	}
	struct ParsedResult_AddressTransactions
	{
		let account_scanned_height: UInt64
		let account_scanned_block_height: UInt64
		let account_scan_start_height: UInt64
		let transaction_height: UInt64
		let blockchain_height: UInt64
		//
		let transactions: [MoneroHistoricalTransactionRecord]
		//
		static func new(
			withLightWallet3Wrapper wrapper: LightWallet3Wrapper
		) -> (
			err_str: String?,
			result: ParsedResult_AddressTransactions?
		) {
			let account_scanned_height = wrapper.scanned_height() as UInt64
			let account_scanned_block_height = wrapper.scanned_block_height() as UInt64
			let account_scan_start_height = wrapper.scan_start_height() as UInt64
			let transaction_height = wrapper.transaction_height() as UInt64
			let blockchain_height = wrapper.blockchain_height() as UInt64
			//
			var mutable_transactions: [MoneroHistoricalTransactionRecord] = []
			let bridge_ordered_address_txs = wrapper.timeOrdered_historicalTransactionRecords() as! [Monero_Bridge_HistoricalTransactionRecord]
			for (_, bridge_address_tx) in bridge_ordered_address_txs.enumerated() {
				let amountPolarity = MoneroAmount("\(bridge_address_tx.isIncoming ? 1 : -1)")!
				let final_tx_amount = MoneroAmount("\(bridge_address_tx.amount as UInt64)")! * amountPolarity
				let height = bridge_address_tx.height
				let unlockTime = bridge_address_tx.unlockTime
				//
				let isConfirmed = MoneroHistoricalTransactionRecord.isConfirmed(
					givenTransactionHeight: height,
					andWalletBlockchainHeight: blockchain_height
				)
				let isUnlocked = MoneroHistoricalTransactionRecord.isUnlocked(
					givenTransactionUnlockTime: unlockTime,
					andWalletBlockchainHeight: blockchain_height
				)
				let lockedReason: String? = !isUnlocked ? MoneroHistoricalTransactionRecord.lockedReason(
					givenTransactionUnlockTime: unlockTime,
					andWalletBlockchainHeight: blockchain_height
				) : nil
				let optl__paymentId = bridge_address_tx.paymentId != nil && bridge_address_tx.paymentId! != "" ?  bridge_address_tx.paymentId as! MoneroPaymentID : nil // TODO: add nullability to bridge property
				let transactionRecord = MoneroHistoricalTransactionRecord(
					amount: final_tx_amount,
					timestamp: bridge_address_tx.timestampDate,
					hash: bridge_address_tx.txHash as MoneroTransactionHash,
					paymentId: optl__paymentId,
					mixin: bridge_address_tx.mixin as UInt32,
					//
					mempool: bridge_address_tx.mempool, // is_unconfirmed
					unlock_time: unlockTime,
					height: height,
					//
					cached__isConfirmed: isConfirmed,
					cached__isUnlocked: isUnlocked,
					cached__lockedReason: lockedReason,
					//
//					id: (dict["id"] as? UInt64)!, // unwrapping this for clarity
					isJustSentTransientTransactionRecord: false
				)
				mutable_transactions.append(transactionRecord)
			}
			let final_transactions = mutable_transactions
			//
			let result = ParsedResult_AddressTransactions(
				account_scanned_height: account_scanned_height,
				account_scanned_block_height: account_scanned_block_height,
				account_scan_start_height: account_scan_start_height,
				transaction_height: transaction_height,
				blockchain_height: blockchain_height,
				//
				transactions: final_transactions
			)
			return (nil, result)
		}
	}
	struct ParsedResult_RandomOuts
	{
		let amount_outs: [MoneroRandomAmountAndOutputs]
		//
		//
		static func newByParsing(
			response_jsonDict: [String: Any]
		) -> (
			err_str: String?,
			result: ParsedResult_RandomOuts?
		) {
			let amount_outs = response_jsonDict["amount_outs"] as! [[String: Any]]
			var mutable__amount_outs: [MoneroRandomAmountAndOutputs] = []
			for (_, dict) in amount_outs.enumerated() {
				let amountAndOutputs = MoneroRandomAmountAndOutputs.new(withAPIJSONDict: dict)
				mutable__amount_outs.append(amountAndOutputs)
			}
			let final_amount_outs = mutable__amount_outs
			let result = ParsedResult_RandomOuts(
				amount_outs: final_amount_outs
			)
			return (nil, result)
		}
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
	//
	case AddressInfo = "get_address_info"
	case AddressTransactions = "get_address_txs"
	//
	case UnspentOuts = "get_unspent_outs"
	case RandomOuts = "get_random_outs"
	//
	case SubmitSerializedSignedTransaction = "submit_raw_tx"
	case ImportRequestInfoAndStatus = "import_wallet_request"
}
//
extension HostedMonero
{
	struct APIClient_HostConfig
	{
		// currently not in use
//		static let hostingServiceFee_depositAddress = "49VNLa9K5ecJo13bwKYt5HCmA8GkgLwpyFjgGKG6qmp8dqoXww8TKPU2PJaLfAAtoZGgtHfJ1nYY8G2YaewycB4f72yFT6u"
		static let hostingServiceFee_txFeeRatioOfNetworkFee = 0.5 // Service fee relative to tx fee (0.5 => 50%)
		//
		static func HostingServiceChargeForTransaction(with networkFee: MoneroAmount) -> MoneroAmount
		{
			let feeRatioReciprocalInteger = MoneroAmount(UInt(1.0/hostingServiceFee_txFeeRatioOfNetworkFee)) // instead of just *, because ratio is not an integer
			let amount = networkFee / feeRatioReciprocalInteger
			return amount
		}
	}
}
//
extension HostedMonero
{
	final class APIClient
	{
		//
		// Static - Singleton
		static let shared = HostedMonero.APIClient()
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
		) {
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
		private func _shared_onMain_callBackFromRequest(
			_ err_str: String?,
			_ fn: @escaping (
				_ err_str: String?
			) -> Void
		) {
			if err_str != nil {
				DDLog.Error("HostedMonero", "\(err_str!)")
			}
			if Thread.isMainThread { // minor
				fn(err_str)
			} else {
				DispatchQueue.main.async
				{
					fn(err_str)
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
		) -> RequestHandle? {
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
			wallet__light_wallet3_wrapper wallet_wrapper: LightWallet3Wrapper,
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_AddressInfo?
			) -> Void
		) -> RequestHandle? {
			let parameters = self._new_parameters_forWalletRequest(
				address: wallet_wrapper.address() as MoneroStandardAddress,
				view_key__private: wallet_wrapper.view_key__private() as MoneroKey
			)
			let endpoint = HostedMoneroAPI_Endpoint.AddressInfo
			let requestHandle = self._request(endpoint, parameters)
			{ [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					wallet_wrapper.ingestJSONString_addressInfo("garbage", or_didError: true)
					// ^- we want to make sure the light_wallet3 gets to set its m_light_wallet_connected back to false
					return
				}
				let response_jsonString = String(data: response_data!, encoding: .utf8)!
				wallet_wrapper.ingestJSONString_addressInfo(response_jsonString, or_didError: false)
				//
				let (err_str, result) = ParsedResult_AddressInfo.new(
					withLightWallet3Wrapper: wallet_wrapper,
					response_jsonDict: response_jsonDict! // this is passed in order to parse MyMonero specific meta-data such as currencies
				)
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}
			return requestHandle
		}
		@discardableResult
		func AddressTransactions(
			wallet__light_wallet3_wrapper wallet_wrapper: LightWallet3Wrapper,
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_AddressTransactions?
			) -> Void
		) -> RequestHandle? {
			let parameters = self._new_parameters_forWalletRequest(
				address: wallet_wrapper.address() as MoneroStandardAddress,
				view_key__private: wallet_wrapper.view_key__private() as MoneroKey
			)
			//
			let endpoint = HostedMoneroAPI_Endpoint.AddressTransactions
			let requestHandle = self._request(endpoint, parameters)
			{ [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					return
				}
				let response_jsonString = String(data: response_data!, encoding: .utf8)!
				wallet_wrapper.ingestJSONString_addressTxs(response_jsonString)
				//
				let (err_str, result) = ParsedResult_AddressTransactions.new(
					withLightWallet3Wrapper: wallet_wrapper
				)
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
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
				_ result: ParsedResult_ImportRequestInfoAndStatus?
			) -> Void
		) -> RequestHandle? {
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
				let result = ParsedResult_ImportRequestInfoAndStatus(
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
			wallet__light_wallet3_wrapper wallet_wrapper: LightWallet3Wrapper,
			_ fn: @escaping (
				_ err_str: String?
				// no return value because values are stored on the wallet_wrapper
			) -> Void
		) -> RequestHandle? {
			let mixinSize = MyMoneroCore.shared.fixedMixinsize
			let parameters: [String: Any] =
			[
				"address": wallet_wrapper.address(),
				"view_key": wallet_wrapper.view_key__private(),
				"amount": "0",
				"mixin": mixinSize,
				"use_dust": mixinSize == 0, // Use dust outputs only when we are using no mixins
				"dust_threshold": String(MoneroConstants.dustThreshold, radix: 10)
			]
			let endpoint = HostedMoneroAPI_Endpoint.UnspentOuts
			let requestHandle = self._request(endpoint, parameters)
			{ [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, fn)
					return
				}
				let response_jsonString = String(data: response_data!, encoding: .utf8)!
				wallet_wrapper.ingestJSONString_unspentOuts(
					response_jsonString,
					mixinSize: mixinSize
				)
				//
				self._shared_onMain_callBackFromRequest(err_str, fn)
			}
			return requestHandle
		}
		func RandomOuts(
			using_outs: [MoneroOutputDescription],
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_RandomOuts?
			) -> Void
		) -> RequestHandle? {
			var amounts = [String]()
			for (_, using_out_desc) in using_outs.enumerated() {
				amounts.append(using_out_desc.rct != nil ? "0" : String(using_out_desc.amount))
			}
			let parameters: [String: Any] =
			[
				"amounts": amounts,
				"count": MyMoneroCore.shared.fixedRingsize  // Add one to mixin so we can skip real output key if necessary
			]
			let endpoint = HostedMoneroAPI_Endpoint.RandomOuts
			let requestHandle = self._request(endpoint, parameters)
			{ (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					return
				}
				let (err_str, result) = ParsedResult_RandomOuts.newByParsing(
					response_jsonDict: response_jsonDict!
				)
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
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
		) -> RequestHandle? {
			#if DEBUG
				#if MOCK_SUCCESSOFTXSUBMISSION
					DDLog.Warn("HostedMonero", "Merely returning mocked success response instead of actually submitting transaction to the server.")
					self._shared_onMain_callBackFromRequest(nil, nil, fn)
					return nil
				#endif
			#endif
			DDLog.Do("HostedMonero", "Submitting transaction…")
			// TODO: would be nice to find a way around the 'code after return won't be executed' warning
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
		) -> RequestHandle? {
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
}
