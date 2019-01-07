//
//  Wallet_TxCleanupController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 9/29/18..
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
//
class Wallet_TxCleanupController
{
	//
	// Properties - Internal
	weak var wallet: Wallet? // prevent retain cycle since wallet owns self
	//
	var localTxCleanupJobTimer: Timer!
	//
	// Lifecycle - Init
	init(
		wallet: Wallet
	) {
		self.wallet = wallet
		self.setup()
	}
	func setup()
	{
		self.__do_localTxCleanupJob()
		self._startTimer__localTxCleanupJob()
	}
	//
	// Lifecycle - Teardown
	deinit
	{
		self.tearDown()
	}
	func tearDown()
	{
		self._stopTimer__localTxCleanupJob()
		//
		self.wallet = nil
	}
	//
	// Accessors
	//
	// Imperatives - Timer
	func _startTimer__localTxCleanupJob()
	{
		// it would be cool to change the sync polling interval to faster while any transactions are pending confirmation, then dial it back while passively waiting
		self.localTxCleanupJobTimer = Timer.scheduledTimer(
			withTimeInterval: 60, // every minute
			repeats: true,
			block:
			{ [weak self] (timer) in
				guard let thisSelf = self else {
					return
				}
				thisSelf.__do_localTxCleanupJob()
			}
		)
	}
	func _stopTimer__localTxCleanupJob()
	{
		DDLog.Info("Wallets", "💬  Clearing polling localTxCleanupJob__intervalTimer.")
		self.localTxCleanupJobTimer.invalidate()
		self.localTxCleanupJobTimer = nil
	}
	//
	// Imperatives - Jobs
	func __do_localTxCleanupJob()
	{
		guard let wallet = self.wallet else {
			DDLog.Warn("Wallets", "Asked to __do_localTxCleanupJob() but self.wallet==nil; skipping.")
			return
		}
		guard let txs = wallet.transactions, txs.count > 0 else {
			return // nothing to do
		}
		var didChangeAny = false
		let oneDayAndABit_s = Double(60 * 60 * (24 + 1/*bit=1hr*/)) // and a bit to avoid possible edge cases
		let tilConsideredRejected_s = oneDayAndABit_s // to be clear
		let timeNow = Date().timeIntervalSince1970
		for (_, existing_tx) in txs.enumerated() {
			let sSinceCreation = timeNow - existing_tx.timestamp.timeIntervalSince1970
			if sSinceCreation < 0 {
				fatalError("Expected non-negative msSinceCreation")
			}
			if sSinceCreation > tilConsideredRejected_s {
				if existing_tx.cached__isConfirmed == false || existing_tx.mempool {
					if existing_tx.isFailed != true/*already*/ {
						DDLog.Info("Wallets", "Marking transaction as dead: \(existing_tx.hash)")
						//
						didChangeAny = true
						existing_tx.isFailed = true  // this flag does not need to get preserved on existing_txs when overwritten by an incoming_tx because if it's returned by the server, it can't be dead
						existing_tx.isJustSentTransientTransactionRecord = false
					}
				}
			}
		}
		if didChangeAny {
			let _ = wallet.saveToDisk()
		}
	}
}
