//
//  HostedMonero_SendingFunds.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
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
import BigInt
//
extension MoneroUtils
{
	struct Fees
	{
		static let newer_multipliers: [UInt32] = [1, 4, 20, 166]
		// TODO: replace this with an enum?
		static func fee_multiplier_for_priority(
			_ priority: MoneroTransferSimplifiedPriority
		) -> UInt32 {
			let priority_as_idx = Int(priority.rawValue - 1)
			if (priority_as_idx < 0 || priority_as_idx >= newer_multipliers.count) {
				fatalError("fee_multiplier_for_priority: priority_as_idx out of newer_multipliers bounds")
			}
			return MoneroUtils.Fees.newer_multipliers[priority_as_idx]
		}
	}
}
//
extension HostedMonero
{
	class FundsSender
	{
		enum ProcessStep
		{
			case none
			case fetchingLatestBalance
			case calculatingFee
			case fetchingDecoyOutputs
			case constructingTransaction // may go back to .calculatingFee
			case submittingTransaction
			//
			var localizedDescription: String {
				switch self {
					case .none:
						return "" // unexpected
					case .fetchingLatestBalance:
						return NSLocalizedString("Fetching latest balance.", comment: "")
					case .calculatingFee:
						return NSLocalizedString("Calculating fee.", comment: "")
					case .fetchingDecoyOutputs:
						return NSLocalizedString("Fetching decoy outputs.", comment: "")
					case .constructingTransaction:
						return NSLocalizedString("Constructing transaction.", comment: "")
					case .submittingTransaction:
						return NSLocalizedString("Submitting transaction.", comment: "")
				}
			}
		}
		//
		var hasSendBeenInitiated: Bool = false
		var isCanceled = false
		//
		var target_address: MoneroAddress! // currency-ready wallet address, but not an OA address (resolve before calling)
		var amount_orNilIfSweeping: HumanUnderstandableCurrencyAmountDouble? // human-understandable number, e.g. input 0.5 for 0.5 XMR ; will be ignored if isSweeping
		var isSweeping: Bool!
		var wallet__public_address: MoneroAddress!
		var wallet__private_keys: MoneroKeyDuo!
		var wallet__public_keys: MoneroKeyDuo!
		var payment_id: MoneroPaymentID?
		var priority: MoneroTransferSimplifiedPriority!
		var wallet__keyImageCache: MoneroUtils.KeyImageCache
		//
		var processStep: ProcessStep = .none
		func updateProcessStep(to processStep: ProcessStep)
		{
			self.processStep = processStep
			self.didUpdateProcessStep_fn?(processStep) // emit
		}
		//
		// TODO: for cancelling?
//		var preSuccess_obtainedSubmitTransactionRequestHandle: (
//			_ requestHandle: APIClient.RequestHandle
//		) -> Void
		var didUpdateProcessStep_fn: ((_ processStep: ProcessStep) -> Void)?
		var success_fn: ((
			_ final_sentAmountWithoutFee: MoneroAmount,
			_ sentPaymentID_orNil: MoneroPaymentID?,
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount,
			_ tx_key: MoneroTransactionSecKey
		) -> Void)?
		var failWithErr_fn: ((
			_ err_str: String
		) -> Void)?
		//
		var _current_request: HostedMonero.APIClient.RequestHandle?
		//
		init(
			target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
			amount_orNilIfSweeping: HumanUnderstandableCurrencyAmountDouble?, // human-understandable number, e.g. input 0.5 for 0.5 XMR
			isSweeping: Bool,
			wallet__public_address: MoneroAddress,
			wallet__private_keys: MoneroKeyDuo,
			wallet__public_keys: MoneroKeyDuo,
			payment_id: MoneroPaymentID?,
			priority: MoneroTransferSimplifiedPriority,
			wallet__keyImageCache: MoneroUtils.KeyImageCache
		) {
			self.target_address = target_address
			self.amount_orNilIfSweeping = amount_orNilIfSweeping
			self.isSweeping = isSweeping
			self.wallet__public_address = wallet__public_address
			self.wallet__private_keys = wallet__private_keys
			self.wallet__public_keys = wallet__public_keys
			self.payment_id = payment_id
			self.priority = priority
			self.wallet__keyImageCache = wallet__keyImageCache
		}
		deinit
		{
			self.cancel()
		}
		func cancel()
		{
			self.isCanceled = true
			if self._current_request != nil {
				self._current_request!.cancel()
				self._current_request = nil
			}
		}
		func send()
		{
			assert(self.hasSendBeenInitiated == false)
			self.hasSendBeenInitiated = true
			//
			assert(self._current_request == nil)
			//
			// status: preparing to send funds…
			if !self.isSweeping && self.amount_orNilIfSweeping! <= 0 {
				self.failWithErr_fn?(NSLocalizedString("The amount you've entered is too low", comment: ""))
				return
			}
			var sending_amount = MoneroAmount.new(withDouble: self.isSweeping ? 0 : self.amount_orNilIfSweeping!) // this will get reassigned below if sweeping, so it's a var
			var using__payment_id = payment_id == "" ? nil : payment_id

			//
			// now _proceedTo_getUnspentOutsUsableForMixin
			assert(self._current_request == nil)
			self.updateProcessStep(to: .fetchingLatestBalance)
			var original_unusedOuts: [MoneroOutputDescription]!
			var feePerB: MoneroAmount!
			self._current_request = HostedMonero.APIClient.shared.UnspentOuts(
				wallet_keyImageCache: wallet__keyImageCache,
				address: wallet__public_address,
				view_key__private: wallet__private_keys.view,
				spend_key__public: wallet__public_keys.spend,
				spend_key__private: wallet__private_keys.spend,
				{ [weak self] (err_str, result) in
					guard let thisSelf = self else {
						return
					}
					thisSelf._current_request = nil
					if thisSelf.isCanceled {
						return
					}
					if let err_str = err_str {
						thisSelf.failWithErr_fn?(err_str)
						return
					}
					feePerB = result!.feePerB
					original_unusedOuts = result!.unusedOutputs
					//
					// ^-- now we're going to try using this minimum fee but the codepath has to be able to be re-entered if we find after constructing the whole tx that it is larger in kb than the minimum fee we're attempting to send it off with
					__reenterable_constructTxAndSend()
				}
			)
			func __reenterable_constructTxAndSend(
				_ passedIn_attemptAt_minimumFee: UInt64? = nil,
				constructionAttemptN: UInt32 = 1
			) { // Now we need to establish some values for balance validation and to construct the transaction
				DDLog.Info("HostedMonero", "Entered re-enterable tx building codepath with original_unusedOuts \(original_unusedOuts!)")
				self.updateProcessStep(to: .calculatingFee)
				//
				let step1_retVals = MyMoneroCore.shared_objCppBridge.send_step1__prepare_params_for_get_decoys(
					sweeping: isSweeping,
					sending_amount: sending_amount.integerRepresentation,
					fee_per_b: feePerB.integerRepresentation,
					priority: priority,
					unspent_outs: original_unusedOuts,
					payment_id: using__payment_id,
					optl__passedIn_attemptAt_fee: passedIn_attemptAt_minimumFee
				)
				if let err_str = step1_retVals.errStr_orNil {
					self.failWithErr_fn?(err_str)
					return
				}
				//
				self.updateProcessStep(to: .fetchingDecoyOutputs)
				assert(self._current_request == nil)
				self._current_request = HostedMonero.APIClient.shared.RandomOuts(
					using_outs: step1_retVals.using_outs!,
					{ [weak self] (err_str, result) in
						guard let thisSelf = self else {
							return
						}
						thisSelf._current_request = nil
						if thisSelf.isCanceled {
							return
						}
						if let err_str = err_str {
							thisSelf.failWithErr_fn?(err_str)
							return
						}
						___createTxAndAttemptToSend(result!.amount_outs)
					}
				)
				func ___createTxAndAttemptToSend(_ mix_outs: [MoneroRandomAmountAndOutputs])
				{
					self.updateProcessStep(to: .constructingTransaction)
					//
					let step2_retVals = MyMoneroCore.shared_objCppBridge.send_step2__try_create_transaction(
						from_address: wallet__public_address,
						wallet__private_keys: wallet__private_keys,
						to_address: target_address,
						payment_id: using__payment_id,
						final_total_wo_fee: step1_retVals.final_total_wo_fee,
						change_amount: step1_retVals.change_amount,
						using_fee: step1_retVals.using_fee,
						priority: priority,
						using_outs: step1_retVals.using_outs!,
						mix_outs: mix_outs,
						fee_per_b: feePerB.integerRepresentation
					)
					if let err_str = step2_retVals.errStr_orNil {
						self.failWithErr_fn?(err_str)
						return
					}
					if step2_retVals.tx_must_be_reconstructed == true {
						DDLog.Info("HostedMonero", "Need to reconstruct the tx with enough of a network fee")
						// this will update status back to .calculatingFee
						if constructionAttemptN > 30 { // just going to avoid an infinite loop here
							self.failWithErr_fn?("Unable to construct a transaction with sufficient fee for unknown reason.")
							return
						}
						__reenterable_constructTxAndSend(
							step2_retVals.fee_actually_needed, // we are re-entering the step1->step2 codepath after updating fee_actually_needed
							constructionAttemptN: constructionAttemptN + 1
						);
						return;
					}
					DDLog.Info("HostedMonero", "Successful tx generation; submitting tx.");
					//
					// status: submitting…
					assert(self._current_request == nil)
					self.updateProcessStep(to: .submittingTransaction)
					self._current_request = HostedMonero.APIClient.shared.SubmitSerializedSignedTransaction(
						address: self.wallet__public_address,
						view_key__private: self.wallet__private_keys.view,
						serializedSignedTx: step2_retVals.serialized_signed_tx!,
						{ [weak self] (err_str, nilValue) in
							guard let thisSelf = self else {
								return
							}
							thisSelf._current_request = nil
							if thisSelf.isCanceled {
								return
							}
							if let err_str = err_str {
								let errStr_localized = String(
									format: NSLocalizedString("Unexpected error while submitting your transaction: %@", comment: ""),
									err_str
								)
								thisSelf.failWithErr_fn?(errStr_localized)
								return
							}
							let (_, d) = MyMoneroCore.shared_objCppBridge.decoded(address: thisSelf.target_address)
							// assuming valid here given successful send
							let final__payment_id: String? = d!.intPaymentId ?? using__payment_id
							let final_fee_amount = MoneroAmount("\(step1_retVals.using_fee)")!
							let finalTotalWOFee_amount = MoneroAmount("\(step1_retVals.final_total_wo_fee)")!
							thisSelf.success_fn?(
								finalTotalWOFee_amount + final_fee_amount, // total sent
								final__payment_id,
								step2_retVals.tx_hash!,
								final_fee_amount,
								step2_retVals.tx_key!
							) // 🎉
						}
					)
	/*				preSuccess_obtainedSubmitTransactionRequestHandle(requestHandle) */
				}
			}
		}
	}
	//
	static func __randomIndex(_ list: [Any]) -> Int
	{
		let randomIndex = Int(arc4random_uniform(UInt32(list.count)))
		return randomIndex
	}
	static func _outputsAndAmountToUseForMixin(
		target_amount: MoneroAmount,
		unusedOuts: [MoneroOutputDescription],
		isSweeping: Bool
	) -> (
		usingOuts: [MoneroOutputDescription],
		usingOutsAmount: MoneroAmount,
		remaining_unusedOuts: [MoneroOutputDescription]
	) {
		DDLog.Info("HostedMonero", "Selecting outputs to use. target: \(FormattedString(fromMoneroAmount: target_amount))")
		var toFinalize_usingOutsAmount = MoneroAmount(0)
		var toFinalize_usingOuts: [MoneroOutputDescription] = []
		var remaining_unusedOuts = unusedOuts // take 'copy' instead of using original so as to prevent issue if we must re-enter tx building fn if fee too low after building
		while toFinalize_usingOutsAmount < target_amount && remaining_unusedOuts.count > 0 {
			// now select and remove a random element from the unused outputs
			let idx = __randomIndex(remaining_unusedOuts)
			let out = remaining_unusedOuts[idx]
			remaining_unusedOuts.remove(at: idx)
			// now select it for usage
			let out_amount = out.amount
			DDLog.Info("HostedMonero", "Found unused output with amount: \(FormattedString(fromMoneroAmount: out_amount)) - \(out)")
			if out_amount < MoneroConstants.dustThreshold {
				if isSweeping == false {
					DDLog.Info("HostedMonero", "Not sweeping, and found a dusty (though maybe mixable) output... skipping it!")
					continue
				}
				if out.rct == nil || out.rct == "" {
					DDLog.Info("HostedMonero", "Sweeping, and found a dusty but unmixable (non-rct) output... skipping it!")
					continue
				} else {
					DDLog.Info("HostedMonero", "Sweeping and found a dusty but mixable (rct) amount... keeping it!")
				}
			}
			toFinalize_usingOuts.append(out)
			toFinalize_usingOutsAmount = toFinalize_usingOutsAmount + out_amount
			DDLog.Info("HostedMonero", "Using output: \(FormattedString(fromMoneroAmount: out_amount)) - \(out)")
		}
		return (
			usingOuts: toFinalize_usingOuts,
			usingOutsAmount: toFinalize_usingOutsAmount,
			remaining_unusedOuts: remaining_unusedOuts
		)
	}
}
