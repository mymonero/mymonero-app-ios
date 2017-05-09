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
import BigInt
//
// Accessory types
typealias MoneroSeed = String
typealias MoneroSeedAsMnemonic = String
typealias MoneroAddress = String
typealias MoneroPaymentID = String
typealias MoneroKey = String
typealias MoneroKeyImage = String
typealias MoneroAmount = BigInt
struct MoneroKeyDuo
{
	var view: MoneroKey
	var spend: MoneroKey
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
// Constants
struct MoneroConstants
{
	static let currency_name = "Monero"
	static let currency_symbol = "XMR"
	static let currency_requestURIPrefix = "monero:"
	static let currency_openAliasPrefix = "xmr" // OpenAlias prefix
	//
	static let addressPrefix = 18 // Prefix code for addresses; 18 => addresses start with "4"
	static let integratedAddressPrefix = 19 // Prefix code for addresses
	//
	static let currency_unitPlaces = 12 // Number of atomic units in one unit of currency. e.g. 12 => 10^12 = 1000000000000
	static let txMinConfirms = 10 // Minimum number of confirmations for a transaction to show as confirmed
	static let maxBlockNumber = 500000000 // Maximum block number, used for tx unlock time
	static let avgBlockTime = 60 // Average block time in seconds, used for unlock time estimation
	//
	static let feePerKB = MoneroAmount("2000000000")! // 0.002 XMR; Network per kb fee in atomic units
	static let dustThreshold = MoneroAmount("10000000000")! // Dust threshold in atomic units; 10^10 used for choosing outputs/change - we decompose all the way down if the receiver wants now regardless of threshold
}
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
	//
	//
	// Interface - Accessors
	// The following functions are implemented in Swift to avoid asynchrony
	override func IsValidPaymentIDOrNoPaymentID(paymentId: String?) -> Bool
	{
		if let paymentId = paymentId {
			let pattern = "^[0-9a-fA-F]{64}$"
			if paymentId.characters.count != 64 || paymentId.range(of: pattern, options: .regularExpression) == nil { // not a valid 64 char pid
				return false // then not valid
			}
		}
		return true // then either no pid or is a valid one
	}
	override func IsTransactionConfirmed(_ tx_height: Int, _ blockchain_height: Int) -> Bool
	{
		return (blockchain_height - tx_height) > MoneroConstants.txMinConfirms
	}
	override func IsTransactionUnlocked(_ tx_unlockTime: Double?, _ blockchain_height: Int) -> Bool
	{
		return self.isTxUnlocked(tx_unlockTime ?? 0, blockchain_height)
	}
	override func TransactionLockedReason(_ tx_unlockTime: Double?, _ blockchain_height: Int) -> String
	{
		return self.txLockedReason(tx_unlockTime ?? 0, blockchain_height)
	}
	//
	//
	// Internal - Accessors - Transaction state parsing implementations
	//
	private func isTxUnlocked(_ tx_unlockTime: Double, _ blockchain_height: Int) -> Bool
	{
		if (tx_unlockTime < Double(MoneroConstants.maxBlockNumber)) { // then unlock time is block height
			return Double(blockchain_height) >= tx_unlockTime
		} else { // then unlock time is s timestamp as TimeInterval
			let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
			return currentTime_s >= tx_unlockTime
		}
	}
	private func txLockedReason(_ tx_unlockTime: Double, _ blockchain_height: Int) -> String
	{
		func colloquiallyFormattedDate(_ date: Date) -> String
		{
			let date_DateInRegion = DateInRegion(absoluteDate: date)
			let date_fromNow_resultTuple = try! date_DateInRegion.colloquialSinceNow(style: .full) // is try! ok? (do we expect failures?)
			let date_fromNow_String = date_fromNow_resultTuple.colloquial
			//
			return date_fromNow_String
		}
		if (tx_unlockTime < Double(MoneroConstants.maxBlockNumber)) { // then unlock time is block height
			let numBlocks = tx_unlockTime - Double(blockchain_height)
			if (numBlocks <= 0) {
				return "Transaction is unlocked"
			}
			let timeUntilUnlock_s = numBlocks * Double(MoneroConstants.avgBlockTime)
			let unlockPrediction_Date = Date().addingTimeInterval(timeUntilUnlock_s)
			let unlockPrediction_fromNow_String = colloquiallyFormattedDate(unlockPrediction_Date)
			//
			return "Will be unlocked in \(numBlocks) blocks, about \(unlockPrediction_fromNow_String)"
		}
		// then unlock time is s timestamp as TimeInterval
		let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
		let time_difference = tx_unlockTime - currentTime_s
		if(time_difference <= 0) {
			return "Transaction is unlocked"
		}
		let unlockTime_Date = Date(timeIntervalSince1970: tx_unlockTime)
		let unlockTime_fromNow_String = colloquiallyFormattedDate(unlockTime_Date)
		//
		return "Will be unlocked \(unlockTime_fromNow_String)"
	}
}
