//
//  MyMoneroTransactions.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import SwiftDate
//
typealias MoneroSignedTransaction = [String: Any]
typealias MoneroSerializedSignedTransaction = String
//
extension MyMoneroCoreUtils
{
	static func IsTransactionConfirmed(_ tx_height: Int, _ blockchain_height: Int) -> Bool
	{
		return (blockchain_height - tx_height) > MoneroConstants.txMinConfirms
	}
	static func IsTxUnlocked(_ tx_unlockTime: Double, _ blockchain_height: Int) -> Bool
	{
		if (tx_unlockTime < Double(MoneroConstants.maxBlockNumber)) { // then unlock time is block height
			return Double(blockchain_height) >= tx_unlockTime
		} else { // then unlock time is s timestamp as TimeInterval
			let currentTime_s = round(Date().timeIntervalSince1970) // TODO: round was ported from cryptonote_utils.js; Do we need it?
			return currentTime_s >= tx_unlockTime
		}
	}
	static func LockedTransactionReason(_ tx_unlockTime: Double, _ blockchain_height: Int) -> String
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
