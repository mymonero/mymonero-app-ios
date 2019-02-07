//
//  HostedMonero.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright (c) 2014-2019, MyMonero.com
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
	enum NotificationNames: String
	{
		case initializedWithNewServerURL = "HostedMonero_NotificationNames_initializedWithNewServerURL"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
}
extension HostedMonero
{
	struct ParsedResult_AddressInfo
	{
		let totalReceived: MoneroAmount
		let totalSent: MoneroAmount
		let lockedBalance: MoneroAmount
		//
		let account_scanned_tx_height: UInt64
		let account_scanned_block_height: UInt64
		let account_scan_start_height: UInt64
		let transaction_height: UInt64
		let blockchain_height: UInt64
		//
		let spentOutputs: [MoneroSpentOutputDescription] // these have a different format than MoneroOutputDescriptions (whose type's name needs to be made more precise)
		//
		let xmrToCcyRatesByCcy: [CcyConversionRates.Currency: Double]
		//
		//
		static func newByParsing(
			response_jsonDict: [String: Any],
			address: MoneroAddress,
			view_key__private: MoneroKey,
			spend_key__public: MoneroKey,
			spend_key__private: MoneroKey,
			wallet_keyImageCache: MoneroUtils.KeyImageCache
		) -> (
			err_str: String?,
			result: ParsedResult_AddressInfo?
		) {
				let total_received = MoneroAmount(response_jsonDict["total_received"] as! String)!
				let locked_balance = MoneroAmount(response_jsonDict["locked_funds"] as! String)!
				var total_sent = MoneroAmount(response_jsonDict["total_sent"] as! String)! // will get modified in-place
				//
				let account_scanned_tx_height = response_jsonDict["scanned_height"] as! UInt64
				let account_scanned_block_height = response_jsonDict["scanned_block_height"] as! UInt64
				let account_scan_start_height = response_jsonDict["start_height"] as! UInt64
				let transaction_height = response_jsonDict["transaction_height"] as! UInt64
				let blockchain_height = response_jsonDict["blockchain_height"] as! UInt64
				let spent_outputs = response_jsonDict["spent_outputs"] as? [[String: Any]] ?? [[String: Any]]()
				//
				var mutable_spentOutputs: [MoneroSpentOutputDescription] = []
				for (_, spent_output) in spent_outputs.enumerated() {
					let generated__keyImage = wallet_keyImageCache.lazy_keyImage(
						tx_pub_key: spent_output["tx_pub_key"] as! MoneroTransactionPubKey,
						out_index: spent_output["out_index"] as! UInt64,
						public_address: address,
						sec_keys: MoneroKeyDuo(view: view_key__private, spend: spend_key__private),
						pub_spendKey: spend_key__public
					)
					let spent_output__keyImage = spent_output["key_image"] as! MoneroKeyImage
					if spent_output__keyImage != generated__keyImage { // not spent
						//				 DDLog.Info(
						//					"HostedMonero",
						//					"Output used as mixin \(spent_output__keyImage)/\(generated__keyImage))"
						//				)
						let spent_output__amount = MoneroAmount(spent_output["amount"] as! String)!
						total_sent -= spent_output__amount
					}
					// TODO: this is faithful to old web wallet code but is it really correct?
					mutable_spentOutputs.append( // but keep output regardless of whether spent or not
						MoneroSpentOutputDescription.new(withAPIJSONDict: spent_output)
					)
				}
				let final_spentOutputs = mutable_spentOutputs
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
					account_scanned_tx_height: account_scanned_tx_height,
					account_scanned_block_height: account_scanned_block_height,
					account_scan_start_height: account_scan_start_height,
					transaction_height: transaction_height,
					blockchain_height: blockchain_height,
					//
					spentOutputs: final_spentOutputs,
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
		//
		static func newByParsing(
			response_jsonDict: [String: Any],
			address: MoneroAddress,
			view_key__private: MoneroKey,
			spend_key__public: MoneroKey,
			spend_key__private: MoneroKey,
			wallet_keyImageCache: MoneroUtils.KeyImageCache
		) -> (
			err_str: String?,
			result: ParsedResult_AddressTransactions?
		) {
			let account_scanned_tx_height = response_jsonDict["scanned_height"] as! UInt64
			let account_scanned_block_height = response_jsonDict["scanned_block_height"] as! UInt64
			let account_scan_start_height = response_jsonDict["start_height"] as! UInt64
			let transaction_height = response_jsonDict["transaction_height"] as! UInt64
			let blockchain_height = response_jsonDict["blockchain_height"] as! UInt64
			//
			var mutable_transactions: [MoneroHistoricalTransactionRecord] = []
			let transaction_dicts = response_jsonDict["transactions"] as? [[String: Any]] ?? []
			for (_, tx_dict) in transaction_dicts.enumerated() {
				assert(blockchain_height != 0)  // if we have txs to parse, I think we can assume height != 0
				//
				var mutable__tx_total_sent = MoneroAmount(tx_dict["total_sent"] as! String)!
				let spent_outputs: [[String: Any]] = tx_dict["spent_outputs"] as? [[String: Any]] ?? []
				var mutable__final_tx_spent_output_dicts = [[String: Any]]()
				for (_, spent_output) in spent_outputs.enumerated() {
					let generated__keyImage = wallet_keyImageCache.lazy_keyImage(
						tx_pub_key: spent_output["tx_pub_key"] as! MoneroTransactionPubKey,
						out_index: spent_output["out_index"] as! UInt64,
						public_address: address,
						sec_keys: MoneroKeyDuo(view: view_key__private, spend: spend_key__private),
						pub_spendKey: spend_key__public
					)
					let spent_output__keyImage = spent_output["key_image"] as! MoneroKeyImage
					if spent_output__keyImage != generated__keyImage { // is NOT own - discard/redact
						//					NSLog("Output used as mixin \(spent_output__keyImage)/\(generated__keyImage))")
						let spent_output__amount = MoneroAmount(spent_output["amount"] as! String)!
						mutable__tx_total_sent -= spent_output__amount
					} else { // IS own - include/keep
						mutable__final_tx_spent_output_dicts.append(spent_output)
					}
				}
				let final_tx_totalSent: MoneroAmount = mutable__tx_total_sent
				let final_tx_spent_output_dicts = mutable__final_tx_spent_output_dicts
				let final_tx_totalReceived = MoneroAmount(tx_dict["total_received"] as! String)! // assuming value exists - default to 0 if n
				if (final_tx_totalReceived + final_tx_totalSent <= 0) {
					continue // skip
				}
				let final_tx_amount = final_tx_totalReceived - final_tx_totalSent
				
				let height = tx_dict["height"] as? UInt64
				let unlockTime = tx_dict["unlock_time"] as? Double ?? 0
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
				//
				let approxFloatAmount = DoubleFromMoneroAmount(moneroAmount: final_tx_amount)
				//
				let record__payment_id = tx_dict["payment_id"] as? MoneroPaymentID
				var final__paymentId = record__payment_id
				if record__payment_id?.count == 16 {
					// short (encrypted) pid
					if approxFloatAmount < 0 {
						// outgoing
						final__paymentId = nil // need to filter these out .. because (afaik) after adding short pid scanning support, the server can't presently filter out short (encrypted) pids on outgoing txs ... not sure this is the optimal or 100% correct solution
					}
				}
				let transactionRecord = MoneroHistoricalTransactionRecord(
					amount: final_tx_amount,
					totalSent: final_tx_totalSent, // must use this as it's been adjusted for non-own outputs
					totalReceived: MoneroAmount("\(tx_dict["total_received"] as! String)")!,
					approxFloatAmount: approxFloatAmount, // -> String -> Double
					spent_outputs: MoneroSpentOutputDescription.newArray(
						withAPIJSONDicts: final_tx_spent_output_dicts // must use this as it's been adjusted for non-own outputs
					),
					timestamp: MoneroJSON_dateFormatter.date(from: "\(tx_dict["timestamp"] as! String)")!,
					hash: tx_dict["hash"] as! MoneroTransactionHash,
					paymentId: final__paymentId,
					mixin: tx_dict["mixin"] as? UInt,
					//
					mempool: tx_dict["mempool"] as! Bool,
					unlock_time: unlockTime,
					height: height,
					//
					isFailed: nil, // since we don't get this from the server
					//
					cached__isConfirmed: isConfirmed,
					cached__isUnlocked: isUnlocked,
					cached__lockedReason: lockedReason,
					//
//					id: (dict["id"] as? UInt64)!, // unwrapping this for clarity
					isJustSentTransientTransactionRecord: false,
					//
					// local-only or sync-only metadata
					tx_key: nil,
					tx_fee: nil,
					to_address: nil
				)
				mutable_transactions.append(transactionRecord)
			}
			mutable_transactions.sort { (a, b) -> Bool in
				return a.timestamp >= b.timestamp // TODO: this used to sort by b.id-a.id in JS… is timestamp sort ok?
			}
			let final_transactions = mutable_transactions
			//
			let result = ParsedResult_AddressTransactions(
				account_scanned_height: account_scanned_tx_height, // account_scanned_tx_height =? account_scanned_height
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
	case SubmitSerializedSignedTransaction = "submit_raw_tx"
	//
	case ImportRequestInfoAndStatus = "import_wallet_request"
}
//
extension HostedMonero
{
	struct APIClient_HostConfig {}
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
			let configuration = URLSessionConfiguration.default
			configuration.timeoutIntervalForResource = 120
			configuration.timeoutIntervalForRequest = 120 // extended - but should maybe be reduced in future or made to work with background requests
			self.manager = SessionManager(
				configuration: configuration,
				serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies_byDomain)
			)
		}
		//
		// Internal - Accessors - Shared
		private func _new_parameters_forWalletRequest(
			address: MoneroAddress,
			view_key__private: MoneroKey
		) -> [String: Any] {
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
		//
		// Login
		struct ParsedResult_Login
		{
			var isANewAddressToServer: Bool
			var generated_locally: Bool? // may be nil if the server doesn't support it yet (pre summer 18)
			var start_height: UInt64?/*UInt64*/ // may be nil if "
			//
			static func new(response_jsonDict: [String: Any]) -> ParsedResult_Login
			{
				return ParsedResult_Login(
					isANewAddressToServer: response_jsonDict["new_address"] as! Bool,
					generated_locally: response_jsonDict["generated_locally"] != nil ? (response_jsonDict["generated_locally"] as! Bool) : nil,
					start_height: response_jsonDict["start_height"] != nil ? (response_jsonDict["start_height"] as! UInt64) : nil
				)
			}
		}
		@discardableResult
		func LogIn(
			address: MoneroAddress,
			view_key__private: MoneroKey,
			generated_locally: Bool,
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_Login?
			) -> Void
		) -> RequestHandle? {
			var parameters = self._new_parameters_forWalletRequest(
				address: address,
				view_key__private: view_key__private
			)
			parameters["create_account"] = true
			parameters["generated_locally"] = generated_locally
			//
			let endpoint = HostedMoneroAPI_Endpoint.LogIn
			let requestHandle = self._request(endpoint, parameters)
			{ [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					return
				}
				let result = ParsedResult_Login.new(response_jsonDict: response_jsonDict!)
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}
			return requestHandle
		}
		//
		// Wallet info / sync
		@discardableResult
		func AddressInfo(
			wallet_keyImageCache: MoneroUtils.KeyImageCache,
			address: MoneroAddress,
			view_key__private: MoneroKey,
			spend_key__public: MoneroKey,
			spend_key__private: MoneroKey,
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_AddressInfo?
			) -> Void
		) -> RequestHandle? {
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
				let (err_str, result) = ParsedResult_AddressInfo.newByParsing(
					response_jsonDict: response_jsonDict!,
					address: address,
					view_key__private: view_key__private,
					spend_key__public: spend_key__public,
					spend_key__private: spend_key__private,
					wallet_keyImageCache: wallet_keyImageCache
				)
				self._shared_onMain_callBackFromRequest(err_str, result, fn)
			}
			return requestHandle
		}
		@discardableResult
		func AddressTransactions(
			wallet_keyImageCache: MoneroUtils.KeyImageCache,
			address: MoneroAddress,
			view_key__private: MoneroKey,
			spend_key__public: MoneroKey,
			spend_key__private: MoneroKey,
			_ fn: @escaping (
				_ err_str: String?,
				_ result: ParsedResult_AddressTransactions?
			) -> Void
		) -> RequestHandle? {
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
				let (err_str, result) = ParsedResult_AddressTransactions.newByParsing(
					response_jsonDict: response_jsonDict!,
					address: address,
					view_key__private: view_key__private,
					spend_key__public: spend_key__public,
					spend_key__private: spend_key__private,
					wallet_keyImageCache: wallet_keyImageCache
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
		@discardableResult func UnspentOuts(
			parameters: [String: Any],
			_ fn: @escaping (
				_ err_str: String?,
				_ response_data: Data?
			) -> Void
		) -> RequestHandle? {
			var final_parameters = parameters
			if let mixin_string = final_parameters["mixin"] as? String {
				final_parameters["mixin"] = Int(mixin_string)!
			}
			if let use_dust_string = final_parameters["use_dust"] as? String {
				final_parameters["use_dust"] = use_dust_string == "true" || use_dust_string == "1" ? true : false
			}
			return self._request(
				HostedMoneroAPI_Endpoint.UnspentOuts,
				final_parameters
			) { [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					return
				}
				self._shared_onMain_callBackFromRequest(err_str, response_data, fn)
			}
		}
		func RandomOuts(
			parameters: [String: Any],
			_ fn: @escaping (
				_ err_str: String?,
				_ response_data: Data?
			) -> Void
		) -> RequestHandle? {
			var final_parameters = parameters
			if let mixin_string = final_parameters["count"] as? String {
				final_parameters["count"] = Int(mixin_string)!
			}
			return self._request(
				HostedMoneroAPI_Endpoint.RandomOuts,
				final_parameters
			) { [unowned self] (err_str, response_data, response_jsonDict) in
				if let err_str = err_str {
					self._shared_onMain_callBackFromRequest(err_str, nil, fn)
					return
				}
				self._shared_onMain_callBackFromRequest(err_str, response_data, fn)
			}
		}
		func SubmitSerializedSignedTransaction(
			parameters: [String: Any],
			_ fn: @escaping (
				_ err_str: String?, // if nil, succeeded
				_ response_data: Data?
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
			return self._request(
				HostedMoneroAPI_Endpoint.SubmitSerializedSignedTransaction,
				parameters
			) { [unowned self] (err_str, response_data, response_jsonDict) in
				self._shared_onMain_callBackFromRequest(err_str, response_data, fn)
			}
		}
		//
		// Private - Runtime - Imperatives - Requests - Shared
		@discardableResult
		public func _request(
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
			DDLog.Net("HostedMonero", "\(url)")
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
			)
			
			DDLog.Info("Networking", "request body: \(String(data: requestHandle.request!.httpBody!, encoding: .utf8)!)")
				
				requestHandle.validate(statusCode: 200..<300).validate(contentType: ["application/json"])
			.responseJSON
			{ /*[unowned self]*/ response in
				let statusCode = response.response?.statusCode ?? -1
				switch response.result
				{
					case .failure(let error):
						print(error)
						DDLog.Error("HostedMonero", "\(url) \(statusCode)")
						var errStr = error.localizedDescription
						if let data = response.data {
							var errDataJSON: [String: Any]
							do {
								errDataJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]
								if let embeddedErrorMessage = errDataJSON["Error"] as? String {
									errStr = String(
										format: NSLocalizedString(
											"Error code %d - %@",
											comment: ""
										),
										statusCode,
										embeddedErrorMessage
									)
								} else {
								}
							} catch {
							}
						} else {
						}
						fn(errStr, nil, nil) // localized description ok here?
						return
					case .success:
						DDLog.Done("HostedMonero", "\(url) \(statusCode)")
						break
				}
				guard let result_value = response.result.value else {
					fn(NSLocalizedString("Unable to find data in response from server.", comment: ""), nil, nil)
					return
				}
				guard let JSON = result_value as? [String: Any] else {
					fn(NSLocalizedString("Unable to find JSON in response from server.", comment: ""), nil, nil)
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
			//
			// Notify consumers to avoid race condition with anyone trying to make a request just before the manager gets de-initialized and re-initialized
			NotificationCenter.default.post(
				name: HostedMonero.NotificationNames.initializedWithNewServerURL.notificationName,
				object: nil
			)
		}
	}
}
