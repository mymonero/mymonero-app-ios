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
	{
		let amount: MoneroAmount
		let public_key: String
		let index: Int
		let globalIndex: Int
		let rct: String?
		let tx_id: Int
		let tx_hash: MoneroTransactionHash
		let tx_pub_key: MoneroTransactionPubKey
		let tx_prefix_hash: MoneroTransactionPrefixHash
		let spend_key_images: [MoneroKeyImage]
		let timestamp: Date
		let height: Int
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
	var JSONParsing_dateFormatter: DateFormatter!
	//
	init() {
		setup()
	}
	func setup()
	{
		self.JSONParsing_dateFormatter = DateFormatter()
		self.JSONParsing_dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
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
		var unspentOutputs: [HostedMoneroAPIClient_Parsing.OutputDescription] = [] // mocked
		var unusedOutputs: [HostedMoneroAPIClient_Parsing.OutputDescription] = [] // mocked
		//
		// MOCKED DATA: - DARK GREY WALLET
		let unspentOut_1 = HostedMoneroAPIClient_Parsing.OutputDescription(
			amount: MoneroAmount("202000000000"),
			public_key: "2ee8b8b5a2201ef17bdd4112cdd80242dcaab30826b87206973c8347c8ffa4dc",
			index: 1,
			globalIndex: 689429,
			rct: "14051b217814eae62febf95e9ee0fa92f5aa7714b1a05ca89ae096494ff81eeee416437476f845c0b2891e9f1d4ef25c283eebd72dbd532463de0b7b74b2b604b29478a9ea4c16d01e67716a8b9d29cb9f49703a15b16f37b73f9e5a2bf2230d",
			tx_id: 2466863,
			tx_hash: "26966c9217160117dc465e959be39264b84819d9875cecc6c8a63c26c7bfc3a3",
			tx_pub_key: "4ff9f870ac27c8f91a8e87d678304801155242c71832dff41a1b64fa8f1fb486",
			tx_prefix_hash: "e4cd3a2ea71bd7c63d8958785c98337bff59dbfda2f8a7f76868e3c9f3d38f84",
			spend_key_images: [
				"c968adaa4c2323409cecfb6c9b170b86e9c1e5edee8ee60a879a949b892eef4b",
				"f6331c40c29efb0adab369f9d6e91dbc74afc19994efb62ae4d93be7fdd82551"
			],
			timestamp: self.JSONParsing_dateFormatter.date(from: "2017-05-15T00:55:33Z")!,
			height: 1295703
		)
		unspentOutputs.append(unspentOut_1)
		let unspentOut_2 = HostedMoneroAPIClient_Parsing.OutputDescription(
			amount: MoneroAmount("10000000000"),
			public_key: "9f00d23f914640a88ddc81f3682cc91ce3397559de2cc254efe0ec66d229fc02",
			index: 0,
			globalIndex: 858164,
			rct: "facf8add95bb6dfb2b1a2e47a601b4f071ae2f4cbe86e5e8e6a637be5fcf53fb34c13823e89c70793e0fd688a76f51fc5512a3e2f5468afbf6e8d1034a02ec0b3b5e4fdf48aecd05af069a609f4aa6f97c95fd2163b827f6e328b2b8407dbb07",
			tx_id: 2530065,
			tx_hash: "cc94ab9561f83c8e9148557c41817ac2c669fab6073bc17710338bc62ee9da00",
			tx_pub_key: "f064954f958ebcd52e5745187cdc05ba7d1e97f6fadfda7d19592a07c4485793",
			tx_prefix_hash: "9b1660d1ae7c1686556b9addb36cb50d7ac1d00d9da93c9c5d367751c8f99b2c",
			spend_key_images: [],
			timestamp: self.JSONParsing_dateFormatter.date(from: "2017-05-15T00:55:33Z")!, // TODO
			height: 1308574
		)
		unspentOutputs.append(unspentOut_2)
		//
		let unusedOut_1 = HostedMoneroAPIClient_Parsing.OutputDescription(
			amount: MoneroAmount("202000000000"),
			public_key: "2ee8b8b5a2201ef17bdd4112cdd80242dcaab30826b87206973c8347c8ffa4dc",
			index: 1,
			globalIndex: 689429,
			rct: "14051b217814eae62febf95e9ee0fa92f5aa7714b1a05ca89ae096494ff81eeee416437476f845c0b2891e9f1d4ef25c283eebd72dbd532463de0b7b74b2b604b29478a9ea4c16d01e67716a8b9d29cb9f49703a15b16f37b73f9e5a2bf2230d",
			tx_id: 2466863,
			tx_hash: "26966c9217160117dc465e959be39264b84819d9875cecc6c8a63c26c7bfc3a3",
			tx_pub_key: "4ff9f870ac27c8f91a8e87d678304801155242c71832dff41a1b64fa8f1fb486",
			tx_prefix_hash: "e4cd3a2ea71bd7c63d8958785c98337bff59dbfda2f8a7f76868e3c9f3d38f84",
			spend_key_images: [
				"c968adaa4c2323409cecfb6c9b170b86e9c1e5edee8ee60a879a949b892eef4b",
				"f6331c40c29efb0adab369f9d6e91dbc74afc19994efb62ae4d93be7fdd82551"
			],
			timestamp: self.JSONParsing_dateFormatter.date(from: "2017-05-15T00:55:33Z")!, // TODO
			height: 1295703
		)
		unusedOutputs.append(unusedOut_1)
		let unusedOut_2 = HostedMoneroAPIClient_Parsing.OutputDescription(
			amount: MoneroAmount("10000000000"),
			public_key: "9f00d23f914640a88ddc81f3682cc91ce3397559de2cc254efe0ec66d229fc02",
			index: 0,
			globalIndex: 858164,
			rct: "facf8add95bb6dfb2b1a2e47a601b4f071ae2f4cbe86e5e8e6a637be5fcf53fb34c13823e89c70793e0fd688a76f51fc5512a3e2f5468afbf6e8d1034a02ec0b3b5e4fdf48aecd05af069a609f4aa6f97c95fd2163b827f6e328b2b8407dbb07",
			tx_id: 2530065,
			tx_hash: "cc94ab9561f83c8e9148557c41817ac2c669fab6073bc17710338bc62ee9da00",
			tx_pub_key: "f064954f958ebcd52e5745187cdc05ba7d1e97f6fadfda7d19592a07c4485793",
			tx_prefix_hash: "9b1660d1ae7c1686556b9addb36cb50d7ac1d00d9da93c9c5d367751c8f99b2c",
			spend_key_images: [],
			timestamp: self.JSONParsing_dateFormatter.date(from: "2017-05-15T00:55:33Z")!, // TODO
			height: 1308574
		)
		unusedOutputs.append(unusedOut_2)
		//
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
			amounts.append(using_out_desc.rct != nil ? "0" : String(using_out_desc.amount))
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
