//
//  HostedMoneroAPIClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
typealias HostedMoneroAPIClient_RequestHandle = String // TODO: via Alamofire
//
struct HostedMoneroAPIClient_Parsing
{
	struct OutputDescription
	{ // TODO
		let amount: MoneroAmount
		let rct: Bool?
	}
	//
	struct ParsedResult_TXTRecords
	{
		let records: [String]
		let dnssec_used: Bool
		let secured: Bool
		let dnssec_fail_reason: String?
	}
	struct ParsedResult_UnspentOuts
	{
		let unspentOutputs: [OutputDescription]
		let unusedOutputs: [OutputDescription]
	}
	struct ParsedResult_RandomOuts
	{
		let amount_outs: [OutputDescription]
	}
}
//
enum HostedMoneroAPI_Endpoints: String
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
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		let endpointPath = HostedMoneroAPI_Endpoints.TXTRecords
		let requestHandle = "" // TODO
		let err_str: String? = nil
		let records = [String]()
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_TXTRecords(
			records: records,
			dnssec_used: false,
			secured: false,
			dnssec_fail_reason: nil
		)
		fn(err_str, result)
		return requestHandle
	}
	//
	//
	// Sending funds
	//
	func UnspentOuts(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		mixinNumber: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
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
		let endpointPath = HostedMoneroAPI_Endpoints.UnspentOuts
		let requestHandle = "" // TODO
		let unspentOutputs: [HostedMoneroAPIClient_Parsing.OutputDescription] = [] // mocked
		let unusedOutputs: [HostedMoneroAPIClient_Parsing.OutputDescription] = [] // mocked
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts(
			unspentOutputs: unspentOutputs,
			unusedOutputs: unusedOutputs
		)
		fn(nil, result)
		return requestHandle
	}
	func RandomOuts(
		using_outs: [HostedMoneroAPIClient_Parsing.OutputDescription],
		mixinNumber: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts?
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		if (mixinNumber < 0) {
			fn("Invalid mixin - must be >= 0", nil)
			return nil
		}
		//
		var amounts = [String]()
		for (_, using_out_desc) in using_outs.enumerated() {
			amounts.append(using_out_desc.rct == true ? "0" : String(using_out_desc.amount))
		}
		let parameters: [String: Any] =
		[
			"amounts": amounts,
			"count": mixinNumber + 1 // Add one to mixin so we can skip real output key if necessary
		]
		let endpointPath = HostedMoneroAPI_Endpoints.RandomOuts
		let requestHandle = "" // TODO
		let amount_outs: [HostedMoneroAPIClient_Parsing.OutputDescription] = [] // mocked
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts(amount_outs: amount_outs)
		fn(nil, result)
		return requestHandle
	}
	func SubmitSerializedSignedTransaction(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		serializedSignedTx: MoneroSerializedSignedTransaction,
		_ fn: @escaping (
			_ err_str: String? // if nil, succeeded
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		
		let requestHandle = "" // TODO
		fn(nil)
		return requestHandle
	}
}
