//
//  HostedMoneroAPIClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
	struct ParsedResult_UnspentOuts
	{
		let unspentOutputs: [MoneroOutputDescription]
		let unusedOutputs: [MoneroOutputDescription]
	}
	struct ParsedResult_RandomOuts
	{
		let amount_outs: [MoneroRandomAmountAndOutputs]
	}
}
//
enum HostedMoneroAPI_Endpoint: String
{
	case UnspentOuts = "get_unspent_outs"
	case RandomOuts = "get_random_outs"
	case TXTRecords = "get_txt_records"
	case SubmitSerializedSignedTransaction = "submit_raw_tx"
}
//
struct HostedMoneroAPIClient_HostConfig
{
	static let hostDomainPlusPortPlusSlash = "api.mymonero.com:8443/"
	static let protocolScheme = "https"
	//
	static let hostingServiceFee_depositAddress = "49VNLa9K5ecJo13bwKYt5HCmA8GkgLwpyFjgGKG6qmp8dqoXww8TKPU2PJaLfAAtoZGgtHfJ1nYY8G2YaewycB4f72yFT6u"
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
class HostedMoneroAPIClient
{
	// Types
	typealias RequestHandle = Alamofire.DataRequest
	// Constants
	let api_hostname = "api.mymonero.com:8443"
	// Properties
	var manager: SessionManager!
	var mymoneroCore: MyMoneroCore!
	//
	init(mymoneroCore: MyMoneroCore)
	{
		self.mymoneroCore = mymoneroCore
		setup()
	}
	func setup()
	{
		self.setup_manager()
	}
	func setup_manager()
	{
		let serverTrustPolicies_byDomain: [String: ServerTrustPolicy] =
		[
			api_hostname: .pinCertificates(
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
	//
	// Open alias lookup - this should be replaced with a lookup implemented
	// on the client, so we can actually use DNSSEC etc
	//
	func TXTRecords(
		openAlias_domain: String,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_TXTRecords?
		) -> Void
	) -> RequestHandle?
	{
		let endpointPath = HostedMoneroAPI_Endpoint.TXTRecords
		let requestHandle: RequestHandle? = nil // TODO
		let err_str: String? = nil
		let records = [String]()
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_TXTRecords(
			records: records,
			dnssec_used: false,
			secured: false,
			dnssec_fail_reason: nil
		)
		DispatchQueue.main.async {
			fn(err_str, result)
		}
		return requestHandle
	}
	//
	//
	// Sending funds
	//
	@discardableResult
	func UnspentOuts(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		mixinNumber: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts?
		) -> Void
	) -> RequestHandle?
	{
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private,
			"amount": "0",
			"mixin": mixinNumber,
			"use_dust": mixinNumber == 0, // Use dust outputs only when we are using no mixins
			"dust_threshold": String(MoneroConstants.dustThreshold, radix: 10)
		]
		let endpoint = HostedMoneroAPI_Endpoint.UnspentOuts
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				print(err_str)
				fn(err_str, nil)
				return
			}
			self.mymoneroCore.Parsed_UnspentOuts(
				response_jsonDict: response_jsonDict!,
				address: address,
				view_key__private: view_key__private,
				spend_key__public: spend_key__public,
				spend_key__private: spend_key__private
			)
			{ (err_str, result) in
				DispatchQueue.main.async
				{ // TODO: centralize this cb w/trampoline on main and use trampoline to call for errs too
					fn(err_str, result)
				}
			}
		}
		return requestHandle
	}
	func RandomOuts(
		using_outs: [MoneroOutputDescription],
		mixin: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts?
		) -> Void
	) -> RequestHandle?
	{
		if (mixin < 0) {
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
			"count": mixin + 1 // Add one to mixin so we can skip real output key if necessary
		]
		let endpoint = HostedMoneroAPI_Endpoint.RandomOuts
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				print(err_str)
				fn(err_str, nil)
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
			DispatchQueue.main.async
			{ // TODO: centralize this cb w/trampoline on main and use trampoline to call for errs too
				fn(nil, result)
			}
		}
		return requestHandle
	}
	func SubmitSerializedSignedTransaction(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		serializedSignedTx: MoneroSerializedSignedTransaction,
		_ fn: @escaping (
			_ err_str: String? // if nil, succeeded
		) -> Void
	) -> RequestHandle?
	{
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private,
			"tx": serializedSignedTx
		]
		let endpoint = HostedMoneroAPI_Endpoint.SubmitSerializedSignedTransaction
		let requestHandle = self._request(endpoint, parameters)
		{ (err_str, response_data, response_jsonDict) in
			if let err_str = err_str {
				print(err_str)
				fn(err_str)
				return
			}
			DispatchQueue.main.async
			{ // TODO: centralize this cb w/trampoline on main and use trampoline to call for errs too
				fn(nil)
			}
		}
		return requestHandle
	}
	//
	//
	// Private - Runtime - Imperatives - Requests - Shared
	//
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
		let url = "https://\(self.api_hostname)/\(endpoint.rawValue)"
		NSLog("📡  \(url)")
		let requestHandle = self.manager.request(
			url,
			method: .post,
			parameters: parameters,
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
					NSLog("❌  \(url) \(statusCode)")
					fn(error.localizedDescription, nil, nil) // localized description ok here?
					return
				case .success:
					NSLog("✅  \(url) \(statusCode)")
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
}
//
extension MyMoneroCoreJS // for Parsing
{
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
		{ (any, err) in
			if let err = err {
				fn(err.localizedDescription, nil)
				return
			}
			let returnValuesByKey = any as! [String: Any]
			let unusedOuts = returnValuesByKey["unusedOuts"] as! [[String: Any]]
			let unspentOutputs = returnValuesByKey["unusedOuts"] as! [[String: Any]]
			//
			var final_unspentOutputs: [MoneroOutputDescription] = []
			do { // finalize
				for (_, dict) in unusedOuts.enumerated() {
					let outputDescription = MoneroOutputDescription.new(withCoreParsed_jsonDict: dict)
					final_unspentOutputs.append(outputDescription)
				}
			}
			var final_unusedOutputs: [MoneroOutputDescription] = []
			do { // finalize
				for (_, dict) in unspentOutputs.enumerated() {
					let outputDescription = MoneroOutputDescription.new(withCoreParsed_jsonDict: dict)
					final_unusedOutputs.append(outputDescription)
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
