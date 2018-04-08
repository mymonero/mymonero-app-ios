//
//  MoneroTypes.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/31/17.
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
import SwiftDate
//
// Shared - Cached
let MoneroJSON_dateFormatter = ISO8601DateFormatter() // we can use this new built in formatter b/c we don't require ms precision
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
	//
	static let txMinConfirms = 10 // Minimum number of confirmations for a transaction to show as confirmed
	static let maxBlockNumber = 500000000 // Maximum block number, used for tx unlock time
	static let avgBlockTime: TimeInterval = 60 // Average block time in seconds, used for unlock time estimation
	//
	static let feePerKB = MoneroAmount("2000000000")! // 0.002 XMR; Network per kb fee in atomic units
	static let dustThreshold = MoneroAmount("10000000000")! // Dust threshold in atomic units; 10^10 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
}
//
// Types
typealias MoneroTypeString = String // a type to, so far, provide some JSON serialization conveniences
extension MoneroTypeString
{
	static func jsArrayString(
		_ array: [MoneroTypeString]
		) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String {
		return "\"\(self)\"" // wrap in quotes, cause it's a string
	}
	var objcSerialized: String {
		return self
	}
	
}
typealias MoneroSeed = MoneroTypeString
typealias MoneroSeedAsMnemonic = MoneroTypeString
typealias MoneroAddress = MoneroTypeString
typealias MoneroStandardAddress = MoneroAddress
typealias MoneroIntegratedAddress = MoneroAddress
typealias MoneroPaymentID = MoneroTypeString
typealias MoneroLongPaymentID = MoneroPaymentID // 32
typealias MoneroShortPaymentID = MoneroPaymentID // 8
typealias MoneroTransactionHash = MoneroTypeString
typealias MoneroTransactionPubKey = MoneroTypeString
typealias MoneroTransactionPrefixHash = MoneroTypeString
typealias MoneroKeyImage = MoneroTypeString
typealias MoneroKey = MoneroTypeString
//
typealias MoneroConvertableCurrencySymbol = String
let MoneroConvertableCurrencySymbol_for_XMR = "XMR"
//
struct MoneroDecodedAddressComponents
{
	var publicKeys: MoneroKeyDuo
	var intPaymentId: MoneroPaymentID? // would be encrypted, i.e. an integrated address
}
@objc class MoneroKeyDuo: NSObject // heavier-weight than I'd like but too useful for ObjC bridge
{
	var view: MoneroKey
	var spend: MoneroKey
	//
	init(
		view: MoneroKey,
		spend: MoneroKey
	) {
		self.view = view
		self.spend = spend
	}
	//
	var jsRepresentationString: String {
		return "{\"view\":\"\(view)\",\"spend\":\"\(spend)\"}"
	}
	var jsonRepresentation: [String: Any] {
		return [
			"view": view,
			"spend": spend
		]
	}
	class func new(
		fromJSONRepresentation jsonRepresentation: [String: Any]
	) -> MoneroKeyDuo {
		return MoneroKeyDuo(
			view: jsonRepresentation["view"] as! MoneroKey,
			spend: jsonRepresentation["spend"] as! MoneroKey
		)
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
	var seed: MoneroSeed?
	var publicAddress: MoneroAddress
	var publicKeys: MoneroKeyDuo
	var privateKeys: MoneroKeyDuo
	var isInViewOnlyMode: Bool
}
typealias MoneroMnemonicWordsetName = MoneroUtils.Mnemonics.MNWords.WordsetName // TODO: so, MoneroUtils_Mnemonics is vendored… is that ok for long-term?
//
class MoneroHistoricalTransactionRecord: Equatable
{
	//
	// Constants
	enum NotificationNames: String
	{
		case willBeDeinitialized = "MoneroHistoricalTransactionRecord.willBeDeinitialized"
		//
		var notificationName: NSNotification.Name {
			return NSNotification.Name(self.rawValue)
		}
	}
	//
	// Properties
	let amount: MoneroAmount
	let totalSent: MoneroAmount
	let totalReceived: MoneroAmount
	let approxFloatAmount: Double
	let spent_outputs: [MoneroSpentOutputDescription]?
	let timestamp: Date
	let hash: MoneroTransactionHash
	let paymentId: MoneroPaymentID?
	let mixin: Int
	//
	let mempool: Bool
	let unlock_time: Double
	let height: Int
	//
	// Transient values
	let cached__isConfirmed: Bool
	let cached__isUnlocked: Bool
	let cached__lockedReason: String? // only calculated if isUnlocked=true
	let isJustSentTransientTransactionRecord: Bool
	//
	// Lifecycle - Init
	required init(
		amount: MoneroAmount,
		totalSent: MoneroAmount,
		totalReceived: MoneroAmount,
		approxFloatAmount: Double,
		spent_outputs: [MoneroSpentOutputDescription]?,
		timestamp: Date,
		hash: MoneroTransactionHash,
		paymentId: MoneroPaymentID?,
		mixin: Int,
		//
		mempool: Bool,
		unlock_time: Double,
		height: Int,
		//
		cached__isConfirmed: Bool,
		cached__isUnlocked: Bool,
		cached__lockedReason: String?,
		isJustSentTransientTransactionRecord: Bool
	) {
		self.amount = amount
		self.totalSent = totalSent
		self.totalReceived = totalReceived
		self.approxFloatAmount = approxFloatAmount
		self.spent_outputs = spent_outputs
		self.timestamp = timestamp
		self.hash = hash
		self.paymentId = paymentId
		self.mixin = mixin
		//
		self.mempool = mempool
		self.unlock_time = unlock_time
		self.height = height
		//
		self.cached__isConfirmed = cached__isConfirmed
		self.cached__isUnlocked = cached__isUnlocked
		self.cached__lockedReason = cached__lockedReason
		self.isJustSentTransientTransactionRecord = isJustSentTransientTransactionRecord
	}
	//
	// Lifecycle - Deinit
	deinit
	{
		//		DDLog.TearingDown("MyMoneroCore", "Tearing down a \(self).")
		//
		NotificationCenter.default.post(name: NotificationNames.willBeDeinitialized.notificationName, object: self)
	}
	//
	// Static - Accessors - Transforms
	static func isConfirmed(
		givenTransactionHeight height: Int,
		andWalletBlockchainHeight blockchain_height: Int
	) -> Bool {
		let differenceInHeight = blockchain_height - height
		//
		return differenceInHeight > MoneroConstants.txMinConfirms
	}
	static func isUnlocked(
		givenTransactionUnlockTime unlock_time: Double,
		andWalletBlockchainHeight blockchain_height: Int
	) -> Bool {
		if unlock_time < Double(MoneroConstants.maxBlockNumber) { // then unlock time is block height
			return Double(blockchain_height) >= unlock_time
		} else { // then unlock time is s timestamp as TimeInterval
			let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
			return currentTime_s >= unlock_time
		}
	}
	static func lockedReason(
		givenTransactionUnlockTime unlock_time: Double,
		andWalletBlockchainHeight blockchain_height: Int
	) -> String {
		func colloquiallyFormattedDate(_ date: Date) -> String
		{
			let date_DateInRegion = DateInRegion(absoluteDate: date)
			let date_fromNow_resultTuple = try! date_DateInRegion.colloquialSinceNow(style: .full) // is try! ok? (do we expect failures?)
			let date_fromNow_String = date_fromNow_resultTuple.colloquial
			//
			return date_fromNow_String
		}
		if (unlock_time < Double(MoneroConstants.maxBlockNumber)) { // then unlock time is block height
			let numBlocks = unlock_time - Double(blockchain_height)
			if (numBlocks <= 0) {
				return "Transaction is unlocked"
			}
			let timeUntilUnlock_s = numBlocks * Double(MoneroConstants.avgBlockTime)
			let unlockPrediction_Date = Date().addingTimeInterval(timeUntilUnlock_s)
			let unlockPrediction_fromNow_String = colloquiallyFormattedDate(unlockPrediction_Date)
			//
			return "Will be unlocked in \(numBlocks) blocks, about \(unlockPrediction_fromNow_String)"
		}
		let unlock_time_TimeInterval = TimeInterval(unlock_time)
		// then unlock time is s timestamp as TimeInterval
		let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
		let time_difference = unlock_time_TimeInterval - currentTime_s
		if(time_difference <= 0) {
			return "Transaction is unlocked"
		}
		let unlockTime_Date = Date(timeIntervalSince1970: unlock_time_TimeInterval)
		let unlockTime_fromNow_String = colloquiallyFormattedDate(unlockTime_Date)
		//
		return "Will be unlocked \(unlockTime_fromNow_String)"
	}
	//
	// Equatable
	static func ==(
		l: MoneroHistoricalTransactionRecord,
		r: MoneroHistoricalTransactionRecord
	) -> Bool {
		if l.amount != r.amount {
			return false
		}
		if l.totalSent != r.totalSent {
			return false
		}
		if l.totalReceived != r.totalReceived {
			return false
		}
		if l.approxFloatAmount != r.approxFloatAmount {
			return false
		}
		if l.spent_outputs == nil && r.spent_outputs == nil
			|| l.spent_outputs! != r.spent_outputs!
		{
			return false
		}
		if l.timestamp != r.timestamp {
			return false
		}
		if l.paymentId != r.paymentId {
			return false
		}
		if l.hash != r.hash {
			return false
		}
		if l.mixin != r.mixin {
			return false
		}
		if l.mempool != r.mempool {
			return false
		}
		if l.unlock_time != r.unlock_time {
			return false
		}
		if l.height != r.height {
			return false
		}
		return true
	}
	//
	static func newArray(
		withCoreParsed_jsonDicts dicts: [[String: Any]],
		wallet__blockchainHeight: Int
	) -> [MoneroHistoricalTransactionRecord] {
		return dicts.map
			{
				return MoneroHistoricalTransactionRecord.new(
					withCoreParsed_jsonDict: $0,
					wallet__blockchainHeight: wallet__blockchainHeight
				)
		}
	}
	static func new(
		withCoreParsed_jsonDict dict: [String: Any],
		wallet__blockchainHeight: Int
	) -> MoneroHistoricalTransactionRecord {
		let height = dict["height"] as! Int
		let unlockTime = dict["unlock_time"] as? Double ?? 0
		//
		let isConfirmed = MoneroHistoricalTransactionRecord.isConfirmed(
			givenTransactionHeight: height,
			andWalletBlockchainHeight: wallet__blockchainHeight
		)
		let isUnlocked = MoneroHistoricalTransactionRecord.isUnlocked(
			givenTransactionUnlockTime: unlockTime,
			andWalletBlockchainHeight: wallet__blockchainHeight
		)
		let lockedReason: String? = !isUnlocked ? MoneroHistoricalTransactionRecord.lockedReason(
			givenTransactionUnlockTime: unlockTime,
			andWalletBlockchainHeight: wallet__blockchainHeight
			) : nil
		//
		let instance = MoneroHistoricalTransactionRecord(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			totalSent: MoneroAmount("\(dict["total_sent"] as! String)")!,
			totalReceived: MoneroAmount("\(dict["total_received"] as! String)")!,
			approxFloatAmount: dict["approx_float_amount"] as! Double,
			spent_outputs: MoneroSpentOutputDescription.newArray(
				withCoreParsed_jsonDicts: dict["spent_outputs"] as? [[String: Any]] ?? []
			),
			timestamp: MoneroJSON_dateFormatter.date(from: "\(dict["timestamp"] as! String)")!,
			hash: dict["hash"] as! MoneroTransactionHash,
			paymentId: dict["payment_id"] as? MoneroPaymentID,
			mixin: dict["mixin"] as! Int,
			//
			mempool: dict["mempool"] as! Bool,
			unlock_time: unlockTime,
			height: height,
			//
			cached__isConfirmed: isConfirmed,
			cached__isUnlocked: isUnlocked,
			cached__lockedReason: lockedReason,
			//
			isJustSentTransientTransactionRecord: false
		)
		return instance
	}
	//
	static func newSerializedDictRepresentation(
		withArray array: [MoneroHistoricalTransactionRecord]
	) -> [[String: Any]] {
		return array.map{ $0.jsonRepresentation }
	}
	var jsonRepresentation: [String: Any]
	{
		var dict: [String: Any] =
			[
				"amount": String(amount, radix: 10),
				"total_sent": String(totalSent, radix: 10),
				"total_received": String(totalReceived, radix: 10),
				//
				"approx_float_amount": approxFloatAmount,
				"spent_outputs": MoneroSpentOutputDescription.newSerializedDictRepresentation(
					withArray: spent_outputs ?? []
				),
				"timestamp": timestamp.timeIntervalSince1970,
				"hash": hash,
				"mixin": mixin,
				"mempool": mempool,
				"unlock_time": unlock_time,
				"height": height
		]
		if let value = paymentId {
			dict["paymentId"] = value
		}
		return dict
	}
	static func new(
		fromJSONRepresentation jsonRepresentation: [String: Any],
		wallet__blockchainHeight: Int
	) -> MoneroHistoricalTransactionRecord {
		let height = jsonRepresentation["height"] as! Int
		let unlockTime = jsonRepresentation["unlock_time"] as! Double
		//
		let isConfirmed = MoneroHistoricalTransactionRecord.isConfirmed(
			givenTransactionHeight: height,
			andWalletBlockchainHeight: wallet__blockchainHeight
		)
		let isUnlocked = MoneroHistoricalTransactionRecord.isUnlocked(
			givenTransactionUnlockTime: unlockTime,
			andWalletBlockchainHeight: wallet__blockchainHeight
		)
		let lockedReason: String? = !isUnlocked ? MoneroHistoricalTransactionRecord.lockedReason(
			givenTransactionUnlockTime: unlockTime,
			andWalletBlockchainHeight: wallet__blockchainHeight
			) : nil
		
		return self.init(
			amount: MoneroAmount(jsonRepresentation["amount"] as! String)!,
			totalSent: MoneroAmount(jsonRepresentation["total_sent"] as! String)!,
			totalReceived: MoneroAmount(jsonRepresentation["total_received"] as! String)!,
			//
			approxFloatAmount: jsonRepresentation["approx_float_amount"] as! Double,
			spent_outputs: MoneroSpentOutputDescription.newArray(
				fromJSONRepresentations: jsonRepresentation["spent_outputs"] as! [[String: Any]]
			),
			timestamp: Date(timeIntervalSince1970: jsonRepresentation["timestamp"] as! TimeInterval), // since we took .timeIntervalSince1970
			hash: jsonRepresentation["hash"] as! MoneroTransactionHash,
			paymentId: jsonRepresentation["paymentId"] as? MoneroPaymentID,
			mixin: jsonRepresentation["mixin"] as! Int,
			mempool: jsonRepresentation["mempool"] as! Bool,
			unlock_time: unlockTime,
			height: height,
			//
			cached__isConfirmed: isConfirmed,
			cached__isUnlocked: isUnlocked,
			cached__lockedReason: lockedReason,
			//
			isJustSentTransientTransactionRecord: false
		)
	}
	static func newArray(
		fromJSONRepresentations array: [[String: Any]],
		wallet__blockchainHeight: Int
	) -> [MoneroHistoricalTransactionRecord] {
		return array.map
		{
			return MoneroHistoricalTransactionRecord.new(
				fromJSONRepresentation: $0,
				wallet__blockchainHeight: wallet__blockchainHeight
			)
		}
	}
}
struct MoneroSpentOutputDescription: Equatable
{
	let amount: MoneroAmount
	let tx_pub_key: MoneroTransactionPubKey
	let key_image: MoneroKeyImage
	let mixin: Int
	let out_index: Int
	//
	// Equatable
	static func ==(
		l: MoneroSpentOutputDescription,
		r: MoneroSpentOutputDescription
	) -> Bool {
		if l.amount != r.amount {
			return false
		}
		if l.tx_pub_key != r.tx_pub_key {
			return false
		}
		if l.key_image != r.key_image {
			return false
		}
		if l.mixin != r.mixin {
			return false
		}
		if l.out_index != r.out_index {
			return false
		}
		return true
	}
	//
	// For API response parsing
	static func newArray(withCoreParsed_jsonDicts dicts: [[String: Any]]) -> [MoneroSpentOutputDescription]
	{
		return dicts.map{ MoneroSpentOutputDescription.new(withCoreParsed_jsonDict: $0) }
	}
	static func new(withCoreParsed_jsonDict dict: [String: Any]) -> MoneroSpentOutputDescription
	{
		let instance = MoneroSpentOutputDescription(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			tx_pub_key: dict["tx_pub_key"] as! String,
			key_image: dict["key_image"] as! MoneroKeyImage,
			mixin: dict["mixin"] as! Int,
			out_index: dict["out_index"] as! Int
		)
		return instance
	}
	//
	// In-Swift serialization
	static func newSerializedDictRepresentation(withArray array: [MoneroSpentOutputDescription]) -> [[String: Any]]
	{
		return array.map{ $0.jsonRepresentation }
	}
	var jsonRepresentation: [String: Any]
	{
		return [
			"amount": String(amount, radix: 10),
			"tx_pub_key": tx_pub_key,
			"key_image": key_image,
			"mixin": mixin,
			"out_index": out_index
		]
	}
	static func new(fromJSONRepresentation jsonRepresentation: [String: Any]) -> MoneroSpentOutputDescription
	{
		return self.init(
			amount: MoneroAmount(jsonRepresentation["amount"] as! String)!,
			tx_pub_key: jsonRepresentation["tx_pub_key"] as! MoneroTransactionPubKey,
			key_image: jsonRepresentation["key_image"] as! MoneroKeyImage,
			mixin: jsonRepresentation["mixin"] as! Int,
			out_index: jsonRepresentation["out_index"] as! Int
		)
	}
	static func newArray(
		fromJSONRepresentations array: [[String: Any]]
	) -> [MoneroSpentOutputDescription] {
		return array.map{ MoneroSpentOutputDescription.new(fromJSONRepresentation: $0) }
	}
}
//
@objc class MoneroOutputDescription: NSObject // so that it can be used from ObjC(pp)
{ // TODO: would be good to make this name more precise, like Monero/Unspent/Unused/Usable/Random/…OutputDescription
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
	init(
		amount: MoneroAmount,
		public_key: String,
		index: Int,
		globalIndex: Int,
		rct: String?,
		tx_id: Int,
		tx_hash: MoneroTransactionHash,
		tx_pub_key: MoneroTransactionPubKey,
		tx_prefix_hash: MoneroTransactionPrefixHash,
		spend_key_images: [MoneroKeyImage],
		timestamp: Date,
		height: Int
	) {
		self.amount = amount
		self.public_key = public_key
		self.index = index
		self.globalIndex = globalIndex
		self.rct = rct
		self.tx_id = tx_id
		self.tx_hash = tx_hash
		self.tx_pub_key = tx_pub_key
		self.tx_prefix_hash = tx_prefix_hash
		self.spend_key_images = spend_key_images
		self.timestamp = timestamp
		self.height = height
	}
	//
	class func new(withCoreParsed_jsonDict dict: [String: Any]) -> MoneroOutputDescription
	{
		let outputDescription = MoneroOutputDescription(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			public_key: dict["public_key"] as! String,
			index: dict["index"] as! Int,
			globalIndex: dict["global_index"] as! Int,
			rct: dict["rct"] as? String,
			tx_id: dict["tx_id"] as! Int,
			tx_hash: dict["tx_hash"] as! String,
			tx_pub_key: dict["tx_pub_key"] as! String,
			tx_prefix_hash: dict["tx_prefix_hash"] as! String,
			spend_key_images: dict["spend_key_images"] as? [String] ?? [],
			timestamp: MoneroJSON_dateFormatter.date(from: "\(dict["timestamp"] as! String)")!,
			height: dict["height"] as! Int
		)
		return outputDescription
	}
	class func jsArrayString(_ array: [MoneroOutputDescription]) -> String
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
		keysAndValuesString += ", \"timestamp\": \"\(MoneroJSON_dateFormatter.string(from: timestamp))\""
		keysAndValuesString += ", \"tx_hash\": \(tx_hash.jsRepresentationString)"
		keysAndValuesString += ", \"tx_id\": \(tx_id)"
		keysAndValuesString += ", \"tx_prefix_hash\": \(tx_pub_key.jsRepresentationString)"
		keysAndValuesString += ", \"tx_pub_key\": \(tx_pub_key.jsRepresentationString)"
		//
		return prefix + keysAndValuesString + suffix
	}
}
@objc class MoneroRandomAmountAndOutputs: NSObject
{
	let amount: MoneroAmount
	let outputs: [MoneroRandomOutputDescription]
	//
	init(
		amount: MoneroAmount,
		outputs: [MoneroRandomOutputDescription]
	) {
		self.amount = amount
		self.outputs = outputs
	}
	//
	class func new(withCoreParsed_jsonDict dict: [String: Any]) -> MoneroRandomAmountAndOutputs
	{
		let dict_outputs = dict["outputs"] as! [[String: Any]]
		let outputs = MoneroRandomOutputDescription.newArray(withCoreParsed_jsonDicts: dict_outputs)
		let amountAndOutputs = MoneroRandomAmountAndOutputs(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			outputs: outputs
		)
		return amountAndOutputs
	}
	class func jsArrayString(_ array: [MoneroRandomAmountAndOutputs]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String
	{
		return "{ \"amount\": \(amount.jsRepresentationString), \"outputs\": \(MoneroRandomOutputDescription.jsArrayString(outputs)) }" // amount.jsRepresentationString will become a "new JSBigInt…"
	}
}
@objc class MoneroRandomOutputDescription: NSObject
{
	let globalIndex: String // seems to be a string in this case - just calling that out here so no parsing mistakes are made
	let public_key: MoneroTransactionPubKey
	let rct: String?
	//
	init(
		globalIndex: String,
		public_key: MoneroTransactionPubKey,
		rct: String?
	) {
		self.globalIndex = globalIndex
		self.public_key = public_key
		self.rct = rct
	}
	//
	class func newArray(withCoreParsed_jsonDicts dicts: [[String: Any]]) -> [MoneroRandomOutputDescription]
	{
		return dicts.map{ new(withCoreParsed_jsonDict: $0) }
	}
	class func new(withCoreParsed_jsonDict dict: [String: Any]) -> MoneroRandomOutputDescription
	{
		let outputDescription = MoneroRandomOutputDescription(
			globalIndex: dict["global_index"] as! String,
			public_key: dict["public_key"] as! MoneroTransactionPubKey,
			rct: dict["rct"] as? String
		)
		return outputDescription
	}
	class func jsArrayString(_ array: [MoneroRandomOutputDescription]) -> String
	{
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String {
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
@objc class SendFundsTargetDescription: NSObject
{ // TODO: namespace
	let address: MoneroAddress
	let amount: MoneroAmount
	//
	init(
		address: MoneroAddress,
		amount: MoneroAmount
	) {
		self.address = address
		self.amount = amount
	}
	//
	class func jsArrayString(
		_ array: [SendFundsTargetDescription]
	) -> String {
		return "[" + array.map{ $0.jsRepresentationString }.joined(separator: ",") + "]"
	}
	var jsRepresentationString: String {
		return "{ \"address\": \"\(address)\", \"amount\": \(amount.jsRepresentationString) }" // amount.jsRepresentationString will become a "new JSBigInt…"
	}
}
typealias MoneroSignedTransaction = [String: Any]
typealias MoneroSerializedSignedTransaction = String
//
enum MoneroTransferSimplifiedPriority: UInt32
{ // TODO: obtain values' specification from C++ somehow, or provisionally via MyMoneroCore_ObjCpp_SimplePriority_*
	case vlow = 1
	case mlow = 2
	case mhigh = 3
	case vhigh = 4
	//
	var cppRepresentation: UInt32 {
		return self.rawValue
	}
	var humanReadableLowercasedString: String {
		switch self {
		case .vlow:
			return NSLocalizedString("low", comment: "")
		case .mlow:
			return NSLocalizedString("medium", comment: "")
		case .mhigh:
			return NSLocalizedString("high", comment: "")
		case .vhigh:
			return NSLocalizedString("very high", comment: "")
		}
	}
}
