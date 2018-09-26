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
	static let dustThreshold = MoneroAmount("2000000000")! // Dust threshold in atomic units; 2*10^9 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
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
typealias MoneroSeedAsMnemonic = MoneroTypeString // see MoneroUtils_Mnemonics for equality impl
typealias MoneroAddress = MoneroTypeString
typealias MoneroStandardAddress = MoneroAddress
typealias MoneroIntegratedAddress = MoneroAddress
typealias MoneroPaymentID = MoneroTypeString
typealias MoneroLongPaymentID = MoneroPaymentID // 32
typealias MoneroShortPaymentID = MoneroPaymentID // 8
typealias MoneroTransactionHash = MoneroTypeString
typealias MoneroTransactionPubKey = MoneroTypeString
typealias MoneroTransactionSecKey = MoneroTypeString
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
	var isSubaddress: Bool
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
	var mnemonicLanguage: MoneroMnemonicWordsetName
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
typealias MoneroMnemonicWordsetName = String
extension MoneroMnemonicWordsetName
{
	var apiSafe: String {
		// convert all lowercase, legacy values to core-cpp compatible
		if self == "english" {
			return "English"
		} else if self == "spanish" {
			return "Español"
		} else if self == "portuguese" {
			return "Português"
		} else if self == "japanese" {
			return "日本語"
		}
		return self // then it's got to be one of the new values that came from core-cpp itself
	}
}
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
	let mixin: UInt
	//
	let mempool: Bool
	let unlock_time: Double
	let height: UInt64? // may not have made it into a block yet!
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
		mixin: UInt,
		//
		mempool: Bool,
		unlock_time: Double,
		height: UInt64?,
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
		givenTransactionHeight height: UInt64?,
		andWalletBlockchainHeight blockchain_height: UInt64
	) -> Bool {
		if height == nil {
			return false // hasn't made it into a block yet
		}
		if height! > blockchain_height { // we'd get a negative number
			// this is probably a tx which is still pending
			return false
		}
		let differenceInHeight = blockchain_height - height!
		//
		return differenceInHeight > MoneroConstants.txMinConfirms
	}
	static func isUnlocked(
		givenTransactionUnlockTime unlock_time: Double,
		andWalletBlockchainHeight blockchain_height: UInt64
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
		andWalletBlockchainHeight blockchain_height: UInt64
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
//		if l.approxFloatAmount != r.approxFloatAmount {
//			return false
//		}
		if l.spent_outputs == nil || l.spent_outputs!.count == 0 && r.spent_outputs != nil && r.spent_outputs!.count != 0
			|| l.spent_outputs != nil && l.spent_outputs!.count != 0 && r.spent_outputs == nil || r.spent_outputs!.count == 0
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
		wallet__blockchainHeight: UInt64
	) -> MoneroHistoricalTransactionRecord {
		let height = jsonRepresentation["height"] as! UInt64
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
			mixin: jsonRepresentation["mixin"] as! UInt,
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
		wallet__blockchainHeight: UInt64
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
	let mixin: UInt
	let out_index: UInt64
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
	static func newArray(withAPIJSONDicts dicts: [[String: Any]]) -> [MoneroSpentOutputDescription]
	{
		return dicts.map{ MoneroSpentOutputDescription.new(withAPIJSONDict: $0) }
	}
	static func new(withAPIJSONDict dict: [String: Any]) -> MoneroSpentOutputDescription
	{
		let instance = MoneroSpentOutputDescription(
			amount: MoneroAmount(dict["amount"] as! String)!,
			tx_pub_key: dict["tx_pub_key"] as! MoneroTransactionPubKey,
			key_image: dict["key_image"] as! MoneroKeyImage,
			mixin: dict["mixin"] as! UInt,
			out_index: dict["out_index"] as! UInt64
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
			mixin: jsonRepresentation["mixin"] as! UInt,
			out_index: jsonRepresentation["out_index"] as! UInt64
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
	let index: UInt64
	let globalIndex: UInt64
	let rct: String?
	let tx_id: Int
	let tx_hash: MoneroTransactionHash
	let tx_pub_key: MoneroTransactionPubKey
	let tx_prefix_hash: MoneroTransactionPrefixHash
	let spend_key_images: [MoneroKeyImage]
	let timestamp: Date
	let height: UInt64
	//
	init(
		amount: MoneroAmount,
		public_key: String,
		index: UInt64,
		globalIndex: UInt64,
		rct: String?,
		tx_id: Int,
		tx_hash: MoneroTransactionHash,
		tx_pub_key: MoneroTransactionPubKey,
		tx_prefix_hash: MoneroTransactionPrefixHash,
		spend_key_images: [MoneroKeyImage],
		timestamp: Date,
		height: UInt64
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
	class func new(withAPIJSONDict dict: [String: Any]) -> MoneroOutputDescription
	{
		let outputDescription = MoneroOutputDescription(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			public_key: dict["public_key"] as! String,
			index: dict["index"] as! UInt64,
			globalIndex: dict["global_index"] as! UInt64,
			rct: dict["rct"] as? String,
			tx_id: dict["tx_id"] as! Int,
			tx_hash: dict["tx_hash"] as! String,
			tx_pub_key: dict["tx_pub_key"] as! String,
			tx_prefix_hash: dict["tx_prefix_hash"] as! String,
			spend_key_images: dict["spend_key_images"] as? [String] ?? [],
			timestamp: MoneroJSON_dateFormatter.date(from: "\(dict["timestamp"] as! String)")!,
			height: dict["height"] as! UInt64
		)
		return outputDescription
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
	class func new(withAPIJSONDict dict: [String: Any]) -> MoneroRandomAmountAndOutputs
	{
		let dict_outputs = dict["outputs"] as! [[String: Any]]
		let outputs = MoneroRandomOutputDescription.newArray(withAPIJSONDicts: dict_outputs)
		let amountAndOutputs = MoneroRandomAmountAndOutputs(
			amount: MoneroAmount("\(dict["amount"] as! String)")!,
			outputs: outputs
		)
		return amountAndOutputs
	}
}
@objc class MoneroRandomOutputDescription: NSObject
{
	let globalIndex: UInt64
	let public_key: MoneroTransactionPubKey
	let rct: String?
	//
	init(
		globalIndex: UInt64,
		public_key: MoneroTransactionPubKey,
		rct: String?
	) {
		self.globalIndex = globalIndex
		self.public_key = public_key
		self.rct = rct
	}
	//
	class func newArray(withAPIJSONDicts dicts: [[String: Any]]) -> [MoneroRandomOutputDescription]
	{
		return dicts.map{ new(withAPIJSONDict: $0) }
	}
	class func new(withAPIJSONDict dict: [String: Any]) -> MoneroRandomOutputDescription
	{
		var globalIndex: UInt64!
		do {
			if let asString = dict["global_index"] as? String {
				globalIndex = UInt64(asString)!
			} else if let asInt = dict["global_index"] as? UInt64 {
				globalIndex = asInt
			} else {
				fatalError("Unparseable global_index")
			}
		}
		let outputDescription = MoneroRandomOutputDescription(
			globalIndex: globalIndex,
			public_key: dict["public_key"] as! MoneroTransactionPubKey,
			rct: dict["rct"] as? String
		)
		return outputDescription
	}
}
typealias MoneroSignedTransaction = [String: Any]
typealias MoneroSerializedSignedTransaction = String
//
enum MoneroTransferSimplifiedPriority: UInt32
{ // TODO: obtain values' specification from C++ somehow, or provisionally via MyMoneroCore_ObjCpp_SimplePriority_*
	case low = 1
	case med = 2
	case high = 3
	case veryhigh = 4
	//
	static var defaultPriority: MoneroTransferSimplifiedPriority = .low
	//
	var cppRepresentation: UInt32 {
		return self.rawValue
	}
	static let allValues_humanReadableCapitalizedStrings: [String] =
	[
		MoneroTransferSimplifiedPriority.low.humanReadableCapitalizedString,
		MoneroTransferSimplifiedPriority.med.humanReadableCapitalizedString,
		MoneroTransferSimplifiedPriority.high.humanReadableCapitalizedString,
		MoneroTransferSimplifiedPriority.veryhigh.humanReadableCapitalizedString
	]
	var humanReadableLowercasedString: String {
		switch self {
			case .low:
				return NSLocalizedString("low", comment: "")
			case .med:
				return NSLocalizedString("medium", comment: "")
			case .high:
				return NSLocalizedString("high", comment: "")
			case .veryhigh:
				return NSLocalizedString("very high", comment: "")
		}
	}
	var humanReadableCapitalizedString: String {
		return self.humanReadableLowercasedString.capitalized
	}
	static func new_priority(
		fromHumanReadableString string: String
	) -> MoneroTransferSimplifiedPriority {
		let final_string = string.lowercased()
		switch final_string {
			case MoneroTransferSimplifiedPriority.low.humanReadableLowercasedString:
				return MoneroTransferSimplifiedPriority.low
			case MoneroTransferSimplifiedPriority.med.humanReadableLowercasedString:
				return MoneroTransferSimplifiedPriority.med
			case MoneroTransferSimplifiedPriority.high.humanReadableLowercasedString:
				return MoneroTransferSimplifiedPriority.high
			case MoneroTransferSimplifiedPriority.veryhigh.humanReadableLowercasedString:
				return MoneroTransferSimplifiedPriority.veryhigh
			default:
				fatalError("Illegal string")
		}
	}
}
