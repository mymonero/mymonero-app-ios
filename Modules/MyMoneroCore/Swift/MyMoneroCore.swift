//
//  MyMoneroCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import UIKit // because we use a WKWebView
import SwiftDate
//
// Accessory types
typealias MoneroTypeString = String // a type to, so far, provide some JSON serialization conveniences
extension MoneroTypeString
{
	static func jsArrayString(_ array: [MoneroTypeString]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		return "\"\(self)\"" // wrap in quotes, cause it's a string
	}
}
typealias MoneroSeed = MoneroTypeString
typealias MoneroSeedAsMnemonic = MoneroTypeString
typealias MoneroAddress = MoneroTypeString
typealias MoneroPaymentID = MoneroTypeString
typealias MoneroTransactionHash = MoneroTypeString
typealias MoneroTransactionPubKey = MoneroTypeString
typealias MoneroTransactionPrefixHash = MoneroTypeString
typealias MoneroKeyImage = MoneroTypeString
typealias MoneroKey = MoneroTypeString
//
struct MoneroDecodedAddressComponents
{
	var publicKeys: MoneroKeyDuo
	var intPaymentId: MoneroPaymentID? // would be encrypted, i.e. an integrated address
}
struct MoneroKeyDuo
{
	var view: MoneroKey
	var spend: MoneroKey
	//
	var jsRepresentationString : String
	{
		return "{\"view\":\"\(view)\",\"spend\":\"\(spend)\"}"
	}
}
struct MoneroWalletDescription
{
	var mnemonic: MoneroSeedAsMnemonic
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
}
struct MoneroVerifiedComponentsForLogIn
{
	var seed: MoneroSeed
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
	var isInViewOnlyMode: Bool
}
enum MoneroMnemonicWordsetName: String
{
	case English = "english"
	case Japanese = "japanese"
	case Spanish = "spanish"
	case Portuguese = "portuguese"
}
//
struct MoneroOutputDescription
{ // TODO: would be nice to make this name more precise, like MoneroRandomOutputDescription
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
	//
	static func jsArrayString(_ array: [MoneroOutputDescription]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		let prefix = "{"
		let suffix = "}"
		var keysAndValuesString = ""
		// many of these don't need to be wrapped in escaped quotes because .jsRepresentationString does so
		keysAndValuesString += "\"amount\": \(amount.jsRepresentationString)"
		keysAndValuesString += ", \"global_index\": \(globalIndex)"
		keysAndValuesString += ", \"height\": \(height)"
		keysAndValuesString += ", \"index\": \(index)"
		keysAndValuesString += ", \"public_key\": \"\(public_key)\""
		if let rct = rct, rct != "" {
			keysAndValuesString += ", \"rct\": \"\(rct)\""
		}
		keysAndValuesString += ", \"spend_key_images\": \(MoneroKeyImage.jsArrayString(spend_key_images))"
		keysAndValuesString += ", \"timestamp\": \"\(MyMoneroJSON_dateFormatter.string(from: timestamp))\""
		keysAndValuesString += ", \"tx_hash\": \(tx_hash.jsRepresentationString)"
		keysAndValuesString += ", \"tx_id\": \(tx_id)"
		keysAndValuesString += ", \"tx_prefix_hash\": \(tx_pub_key.jsRepresentationString)"
		keysAndValuesString += ", \"tx_pub_key\": \(tx_pub_key.jsRepresentationString)"
		//
		return prefix + keysAndValuesString + suffix
	}
}
struct MoneroRandomAmountAndOutputs
{
	let amount: MoneroAmount
	let outputs: [MoneroRandomOutputDescription]
	//
	static func jsArrayString(_ array: [MoneroRandomAmountAndOutputs]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		return "{ \"amount\": \(amount.jsRepresentationString), \"outputs\": \(MoneroRandomOutputDescription.jsArrayString(outputs)) }" // amount.jsRepresentationString will become a "new JSBigInt…"
	}
}
struct MoneroRandomOutputDescription
{
	let globalIndex: String // seems to be a string in this case - just calling that out here so no parsing mistakes are made
	let public_key: MoneroTransactionPubKey
	let rct: String?
	//
	static func jsArrayString(_ array: [MoneroRandomOutputDescription]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		let prefix = "{"
		let suffix = "}"
		var keysAndValuesString = ""
		keysAndValuesString += "\"global_index\": \"\(globalIndex)\"" // since it's a string in this case (for RandomOuts), we should wrap in escaped quotes
		keysAndValuesString += ", \"public_key\": \(public_key.jsRepresentationString)"
		if let rct = rct, rct != "" {
			keysAndValuesString += ", \"rct\": \"\(rct)\""
		}
		//
		return prefix + keysAndValuesString + suffix
	}
}
let MyMoneroJSON_dateFormatter = ISO8601DateFormatter() // we can use this new built in formatter b/c we don't require ms precision
//
struct SendFundsTargetDescription
{ // TODO: namespace
	let address: MoneroAddress
	let amount: MoneroAmount
	//
	static func jsArrayString(_ array: [SendFundsTargetDescription]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		return "{ \"address\": \"\(address)\", \"amount\": \(amount.jsRepresentationString) }" // amount.jsRepresentationString will become a "new JSBigInt…"
	}
}
//
func FixedMixin() -> Int
{ // TODO: namespace
	return 9 // for now
}
//
// Constants
struct MoneroConstants
{
	static let currency_name = "Monero"
	static let currency_symbol = "XMR"
	static let currency_requestURIPrefix = "monero:"
	static let currency_requestURIPrefix_sansColon = "monero"
	static let currency_openAliasPrefix = "xmr" // OpenAlias prefix
	//
	static let addressPrefix = 18 // Prefix code for addresses; 18 => addresses start with "4"
	static let integratedAddressPrefix = 19 // Prefix code for addresses
	//
	static let currency_unitPlaces = 12 // Number of atomic units in one unit of currency. e.g. 12 => 10^12 = 
	
	static let txMinConfirms = 10 // Minimum number of confirmations for a transaction to show as confirmed
	static let maxBlockNumber = 500000000 // Maximum block number, used for tx unlock time
	static let avgBlockTime = 60 // Average block time in seconds, used for unlock time estimation
	//
	static let feePerKB = MoneroAmount("2000000000")! // 0.002 XMR; Network per kb fee in atomic units
	static let dustThreshold = MoneroAmount("10000000000")! // Dust threshold in atomic units; 10^10 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
}
//
// Namespaces
struct MyMoneroCoreUtils {}
//
// Principal type
class MyMoneroCore : MyMoneroCoreJS
// TODO? alternative to subclassing MyMoneroCoreJS would be to hold an instance of it and provide proxy fns as interface.
// 
{
	override init(window: UIWindow)
	{
		super.init(window: window)
	}
}
