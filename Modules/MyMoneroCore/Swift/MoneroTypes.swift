//
//  MoneroTypes.swift
//  MyMonero
//
//  Created by Paul Shapiro on 8/31/17.
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
	var objcSerialized: String {
		return self
	}
	
}
typealias MoneroSeed = MoneroTypeString
typealias MoneroSeedAsMnemonic = MoneroTypeString // see MoneroUtils_Mnemonics for equality impl
typealias MoneroAddress = MoneroTypeString
typealias MoneroStandardAddress = MoneroAddress
typealias MoneroIntegratedAddress = MoneroAddress
typealias MoneroSubAddress = MoneroAddress
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
	var apiSafeMnemonicLanguage: String {
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
	var correspondingLanguageCode: String {
		let idxOf = MoneroMnemonicWordsetName.mnemonic_languages.index(of: self)!
		//
		return MoneroMnemonicWordsetName.supported_short_codes[idxOf]
	}
	static var supported_short_codes: [String]
	{
		return [
			"en",
			"nl",
			"fr",
			"es",
			"pt",
			"ja",
			"it",
			"de",
			"ru",
			"zh", // chinese (simplified)
			"eo",
			"jbo" // Lojban
		]
	}
	static var mnemonic_languages: [String]
	{
		return [
			"English",
			"Netherlands",
			"Français",
			"Español",
			"Português",
			"日本語",
			"Italiano",
			"Deutsch",
			"русский язык",
			"简体中文 (中国)",
			"Esperanto",
			"Lojban"
		]
	}
	static func mnemonic_language_from(locale_code: String) -> String
	{
		let compatible_code = MoneroMnemonicWordsetName.compatible_code_from_locale(
			locale_code
		)
		let idx = MoneroMnemonicWordsetName.supported_short_codes.index(of: compatible_code)!
		//
		return MoneroMnemonicWordsetName.mnemonic_languages[idx]
	}
	static func compatible_code_from_locale(_ locale_string: String) -> String
	{
		let codes = self.supported_short_codes // cache access
		for (_, short_code) in codes.enumerated() {
			if locale_string.hasPrefix(short_code) {
				return short_code
			}
		}
		fatalError("Didn't find a code")
		// return undefined
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
	var amount: MoneroAmount
	var totalSent: MoneroAmount
	var totalReceived: MoneroAmount
	var approxFloatAmount: Double
	let spent_outputs: [MoneroSpentOutputDescription]?
	let timestamp: Date
	let hash: MoneroTransactionHash
	var paymentId: MoneroPaymentID? // this is made mutable so it can be recovered if saved only locally
	var mixin: UInt? // this is made mutable so it can be recovered if saved only locally
	//
	let mempool: Bool
	let unlock_time: Double
	let height: UInt64? // may not have made it into a block yet!
	//
	// these properties are made mutable so they can be updated conveniently during a merge/sync from remote
	var tx_key: MoneroTransactionSecKey?
	var tx_fee: MoneroAmount?
	var to_address: MoneroAddress?
	var isFailed: Bool? // set to mutable to allow changing in-place
	//
	// Transient values
	let cached__isConfirmed: Bool
	let cached__isUnlocked: Bool
	let cached__lockedReason: String? // only calculated if isUnlocked=true
	var isJustSentTransientTransactionRecord: Bool // allowed to be mutable for modification during tx cleanup
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
		mixin: UInt?,
		//
		mempool: Bool,
		unlock_time: Double,
		height: UInt64?,
		//
		isFailed: Bool?,
		cached__isConfirmed: Bool,
		cached__isUnlocked: Bool,
		cached__lockedReason: String?,
		isJustSentTransientTransactionRecord: Bool,
		//
		tx_key: MoneroTransactionSecKey?,
		tx_fee: MoneroAmount?,
		to_address: MoneroAddress?
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
		self.isFailed = isFailed
		self.cached__isConfirmed = cached__isConfirmed
		self.cached__isUnlocked = cached__isUnlocked
		self.cached__lockedReason = cached__lockedReason
		self.isJustSentTransientTransactionRecord = isJustSentTransientTransactionRecord
		//
		self.tx_key = tx_key
		self.tx_fee = tx_fee
		self.to_address = to_address
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
				return NSLocalizedString("Transaction is unlocked", comment: "")
			}
			let timeUntilUnlock_s = numBlocks * Double(MoneroConstants.avgBlockTime)
			let unlockPrediction_Date = Date().addingTimeInterval(timeUntilUnlock_s)
			let unlockPrediction_fromNow_String = colloquiallyFormattedDate(unlockPrediction_Date)
			//
			return String(format:
				NSLocalizedString("Will be unlocked in %d blocks, about %@", comment: "Will be unlocked in {number} blocks, about {duration of time plus 'from now'}"),
				numBlocks,
				unlockPrediction_fromNow_String
			)
		}
		let unlock_time_TimeInterval = TimeInterval(unlock_time)
		// then unlock time is s timestamp as TimeInterval
		let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
		let time_difference = unlock_time_TimeInterval - currentTime_s
		if(time_difference <= 0) {
			return NSLocalizedString("Transaction is unlocked", comment: "")
		}
		let unlockTime_Date = Date(timeIntervalSince1970: unlock_time_TimeInterval)
		let unlockTime_fromNow_String = colloquiallyFormattedDate(unlockTime_Date)
		//
		return String(format: NSLocalizedString("Will be unlocked %@", comment: "Will be unlocked {duration of time plus 'from now'}"), unlockTime_fromNow_String)
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
		if l.isFailed != r.isFailed {
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
			"mempool": mempool,
			"unlock_time": unlock_time
		]
		if mixin != nil {
			dict["mixin"] = mixin
		}
		if height != nil {
			dict["height"] = height
		}
		if let value = paymentId {
			dict["paymentId"] = value
		}
		if let value = tx_key {
			dict["tx_key"] = value
		}
		if let value = tx_fee {
			dict["tx_fee"] = String(value, radix: 10)
		}
		if let value = to_address {
			dict["to_address"] = value
		}
		if let value = isFailed {
			dict["isFailed"] = value
		}
		//
		return dict
	}
	static func new(
		fromJSONRepresentation jsonRepresentation: [String: Any],
		wallet__blockchainHeight: UInt64
	) -> MoneroHistoricalTransactionRecord {
		let height = jsonRepresentation["height"] as? UInt64
		let unlockTime = jsonRepresentation["unlock_time"] as! Double
		//
		let isFailed = jsonRepresentation["isFailed"] as? Bool
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
		var tx_fee: MoneroAmount? = nil
		if let tx_fee_string = jsonRepresentation["tx_fee"] as? String {
			tx_fee = MoneroAmount(tx_fee_string)!
		}
		//
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
			isFailed: isFailed,
			cached__isConfirmed: isConfirmed,
			cached__isUnlocked: isUnlocked,
			cached__lockedReason: lockedReason,
			//
			isJustSentTransientTransactionRecord: false,
			tx_key: jsonRepresentation["tx_key"] as? MoneroTransactionSecKey,
			tx_fee: tx_fee,
			to_address: jsonRepresentation["to_address"] as? String
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
