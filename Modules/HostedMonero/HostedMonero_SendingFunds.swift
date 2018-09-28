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
		static let newer_multipliers: [UInt] = [1, 4, 20, 166]
		// TODO: replace this with an enum?
		static func fee_multiplier_for_priority(
			_ priority: MoneroTransferSimplifiedPriority
		) -> UInt {
			let priority_as_idx = Int(priority.rawValue - 1)
			if (priority_as_idx < 0 || priority_as_idx >= newer_multipliers.count) {
				fatalError("fee_multiplier_for_priority: priority_as_idx out of newer_multipliers bounds")
			}
			return MoneroUtils.Fees.newer_multipliers[priority_as_idx]
		}
		
		static func estimateRctSize(
			_ inputs: UInt, // number of
			_ mixin: UInt,
			_ outputs: UInt // number of
		) -> UInt {
			var size: UInt = 0
			// tx prefix
			// first few bytes
			size += 1 + 6;
			size += inputs * (1+6+(mixin+1)*3+32); // original C implementation is *2+32 but author advised to change 2 to 3 as key offsets are variable size and this constitutes a best guess
			// vout
			size += outputs * (6+32);
			// extra
			size += 40;
			// rct signatures
			// type
			size += 1;
			// rangeSigs
			size += (2*64*32+32+64*32) * outputs;
			// MGs
			size += inputs * (32 * (mixin+1) + 32);
			// mixRing - not serialized, can be reconstructed
			/* size += 2 * 32 * (mixin+1) * inputs; */
			// pseudoOuts
			size += 32 * inputs;
			// ecdhInfo
			size += 2 * 32 * outputs;
			// outPk - only commitment is saved
			size += 32 * outputs;
			// txnFee
			size += 4;
			//
			return UInt(size)
		}
		static func estimated_neededNetworkFee(
			_ mixin: UInt,
			_ feePerKB: MoneroAmount,
			_ priority: MoneroTransferSimplifiedPriority // TODO: implement
		) -> MoneroAmount {
			let numberOf_inputs: UInt = 2 // this might change -- might select inputs
			let numberOf_outputs: UInt = 1/*dest*/ + 1/*change*/ + 0/*no mymonero fee presently*/
			// TODO: update est tx size for bulletproofs
			// TODO: normalize est tx size fn naming
			let estimated_txSize_bytes = estimateRctSize(numberOf_inputs, mixin, numberOf_outputs)
			let estimated_fee = calculate_fee(feePerKB, estimated_txSize_bytes, fee_multiplier_for_priority(priority))
			//
			return estimated_fee
		}
		static func calculate_fee__kb(
			_ fee_per_kb: MoneroAmount,
			_ numberOf_kb: UInt,
			_ fee_multiplier: UInt
		) -> MoneroAmount {
			let fee = fee_per_kb * MoneroAmount("\(fee_multiplier)")! * MoneroAmount("\(numberOf_kb)")!
			//
			return fee
		}
		static func calculate_fee(
			_ fee_per_kb: MoneroAmount,
			_ numberOf_bytes: UInt,
			_ fee_multiplier: UInt
		) -> MoneroAmount {
			let numberOf_kb: UInt = (numberOf_bytes + 1023) / 1024 // i.e. ceil
			//
			return calculate_fee__kb(fee_per_kb, numberOf_kb, fee_multiplier)
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
			var totalAmountWithoutFee = MoneroAmount.new(withDouble: self.isSweeping ? 0 : self.amount_orNilIfSweeping!) // this will get reassigned below if sweeping, so it's a var
		//	DDLog.Info("HostedMonero", "targetDescription \(targetDescription)")
			let amountForDisplay: Any = self.isSweeping ? "all" : totalAmountWithoutFee // Swift compiler bug? when amountForDisplay rhs value placed in string interpolation, it tries to init a BigInt with "all"
			DDLog.Info("HostedMonero", "Total to send, before fee: \(amountForDisplay)")
			//
			// Derive/finalize some values…
			let final__mixin = MyMoneroCore.fixedMixin
			if final__mixin <= 0 { // TODO: min mixin checking
				self.failWithErr_fn?(NSLocalizedString("Expected mixin > 0", comment: ""))
				return
			}
			if final__mixin < MyMoneroCore.thisFork_minMixin {
				self.failWithErr_fn?(NSLocalizedString("Ringsize is below the minimum.", comment: ""))
				return
			}
			var final__payment_id = payment_id == "" ? nil : payment_id
			var final__pid_encrypt = false // we don't want to encrypt payment ID unless we find an integrated one (finalized just below)
			let (err_str, decodedAddressComponents) = MyMoneroCore.shared_objCppBridge.decoded(address: target_address)
			if let _ = err_str {
				self.failWithErr_fn?(NSLocalizedString("Invalid recipient address.", comment: ""))
				return
			}
			guard let _ = decodedAddressComponents else {
				self.failWithErr_fn?(NSLocalizedString("Error obtaining decoded recipient Monero address components.", comment: ""))
				return
			}
			let isIntegratedAddress = decodedAddressComponents!.intPaymentId != nil
			if self.payment_id != nil && self.payment_id != "" {
				if isIntegratedAddress { // is integrated address
					self.failWithErr_fn?(NSLocalizedString("Payment ID must be blank when using an Integrated Address", comment: ""))
					return
				}
				if decodedAddressComponents!.isSubaddress {
					self.failWithErr_fn?(NSLocalizedString("Payment ID must be blank when using a Subaddress", comment: ""))
					return
				}
			}
			if isIntegratedAddress {
				final__payment_id = decodedAddressComponents!.intPaymentId
				final__pid_encrypt = true // we do want to encrypt if using an integrated address
				assert(MoneroUtils.PaymentIDs.isAValid(paymentId: final__payment_id!, ofVariant: .short))
			} else {
				if MoneroUtils.PaymentIDs.isAValidOrNotA(paymentId: final__payment_id) == false { // Validation
					self.failWithErr_fn?(NSLocalizedString("The payment ID you've entered is not valid", comment: ""))
					return
				}
				if final__payment_id != nil {
					final__pid_encrypt = MoneroUtils.PaymentIDs.isAValid(paymentId: final__payment_id!, ofVariant: .short) // if it's a short pid, encrypt
				}
			}
			//
			// now _proceedTo_getUnspentOutsUsableForMixin
			assert(self._current_request == nil)
			self.updateProcessStep(to: .fetchingLatestBalance)
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
					let feePerKB = result!.feePerKB
					// Transaction will need at least 1KB fee (13KB for RingCT)
					let network_minimumTXSize_kb: UInt = 13 // because isRingCT=true
					let network_minimumFee = MoneroUtils.Fees.calculate_fee__kb(feePerKB, network_minimumTXSize_kb, MoneroUtils.Fees.fee_multiplier_for_priority(thisSelf.priority))
					// ^-- now we're going to try using this minimum fee but the codepath has to be able to be re-entered if we find after constructing the whole tx that it is larger in kb than the minimum fee we're attempting to send it off with
					__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
						original_unusedOuts: result!.unusedOutputs,
						feePerKB: feePerKB,
						passedIn_attemptAt_network_minimumFee: network_minimumFee
					)
				}
			)
			func __reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
				original_unusedOuts: [MoneroOutputDescription],
				feePerKB: MoneroAmount,
				passedIn_attemptAt_network_minimumFee: MoneroAmount
			) { // Now we need to establish some values for balance validation and to construct the transaction
				DDLog.Info("HostedMonero", "Entered re-enterable tx building codepath with original_unusedOuts \(original_unusedOuts)")
				self.updateProcessStep(to: .calculatingFee)
				//
				var this_attemptAt_network_minimumFee = passedIn_attemptAt_network_minimumFee // we may change this if isRingCT
				var totalAmountIncludingFees: MoneroAmount
				if self.isSweeping {
					totalAmountIncludingFees = MoneroAmount("18450000000000000000")! //~uint64 max
				} else {
					totalAmountIncludingFees = totalAmountWithoutFee + this_attemptAt_network_minimumFee/* + hostingService_chargeAmount NOTE service fee removed for now */
				}
				let balanceForDisplay: Any = self.isSweeping ? "all" : totalAmountIncludingFees // Swift compiler bug? when amountForDisplay rhs value placed in string interpolation, it tries to init a BigInt with "all"
				DDLog.Info("HostedMonero", "Initial balance required: \(balanceForDisplay)");
				let usableOutputsAndAmounts = _outputsAndAmountToUseForMixin(
					target_amount: totalAmountIncludingFees,
					unusedOuts: original_unusedOuts,
					isSweeping: self.isSweeping
				)
				DDLog.Info("HostedMonero", "usableOutputsAndAmounts \(usableOutputsAndAmounts)")
				// v-- now, since isRingCT=true, compute fee as closely as possible before hand
				var usingOuts = usableOutputsAndAmounts.usingOuts
				var usingOutsAmount = usableOutputsAndAmounts.usingOutsAmount
				var remaining_unusedOuts = usableOutputsAndAmounts.remaining_unusedOuts
				//
				var newNeededFee = MoneroUtils.Fees.calculate_fee(
					feePerKB,
					MoneroUtils.Fees.estimateRctSize(UInt(usingOuts.count), final__mixin, 2),
					MoneroUtils.Fees.fee_multiplier_for_priority(self.priority)
				)
				// if newNeededFee < neededFee, use neededFee instead (should only happen on the 2nd or later times through (due to estimated fee being too low)
				if newNeededFee < this_attemptAt_network_minimumFee {
					newNeededFee = this_attemptAt_network_minimumFee
				}
				if self.isSweeping {
					/*
					// When/if sending to multiple destinations supported, uncomment and port this:
					if (dsts.length !== 1) {
					deferred.reject("Sweeping to multiple accounts is not allowed");
					return;
					}
					*/
					totalAmountWithoutFee = usingOutsAmount - newNeededFee
					if totalAmountWithoutFee <= 0 {
						let errStr = String(format:
							NSLocalizedString("Your spendable balance is too low. Have %@ %@ spendable, need %@ %@.", comment: ""),
							FormattedString(fromMoneroAmount: usingOutsAmount),
							MoneroConstants.currency_symbol,
							FormattedString(fromMoneroAmount: newNeededFee),
							MoneroConstants.currency_symbol
						)
						self.failWithErr_fn?(errStr)
						return
					}
					totalAmountIncludingFees = totalAmountWithoutFee + newNeededFee
				} else {
					totalAmountIncludingFees = totalAmountWithoutFee + newNeededFee/* NOTE service fee removed for now, but when we add it back, don't we need to add it to here here? */
					// add outputs 1 at a time till we either have them all or can meet the fee
					while usingOutsAmount < totalAmountIncludingFees && remaining_unusedOuts.count > 0 {
						// pop and return random element from list
						let idx = __randomIndex(remaining_unusedOuts)
						let out = remaining_unusedOuts[idx]
						remaining_unusedOuts.remove(at: idx)
						//
						usingOuts.append(out)
						usingOutsAmount = usingOutsAmount + out.amount
						DDLog.Info("HostedMonero", "Using output: \(FormattedString(fromMoneroAmount: out.amount)) - \(out)")
						// and recalculate invalidated values
						newNeededFee = MoneroUtils.Fees.calculate_fee(
							feePerKB,
							MoneroUtils.Fees.estimateRctSize(UInt(usingOuts.count), final__mixin, 2),
							MoneroUtils.Fees.fee_multiplier_for_priority(self.priority)
						)
						totalAmountIncludingFees = totalAmountWithoutFee + newNeededFee
					}
				}
				DDLog.Info("HostedMonero", "New fee: \(FormattedString(fromMoneroAmount: newNeededFee)) for \(usingOuts.count) inputs")
				this_attemptAt_network_minimumFee = newNeededFee // update with new attempt
				//
				DDLog.Info("HostedMonero", "~ Balance required: \(FormattedString(fromMoneroAmount: totalAmountIncludingFees))")
				// Now we can validate available balance with usingOutsAmount (TODO? maybe this check can be done before selecting outputs?)
				if usingOutsAmount < totalAmountIncludingFees {
					let errStr_localized = String(format:
						NSLocalizedString("Your spendable balance is too low. Have %@ %@ spendable, need %@ %@.", comment: ""),
						FormattedString(fromMoneroAmount: usingOutsAmount),
						MoneroConstants.currency_symbol,
						FormattedString(fromMoneroAmount: totalAmountIncludingFees),
						MoneroConstants.currency_symbol
					)
					self.failWithErr_fn?(errStr_localized)
					return
				}
				var changeAmount: MoneroAmount = 0 // to finalize
				if usingOutsAmount > totalAmountIncludingFees {
					if self.isSweeping {
						assert(false, "Unexpected usingOutsAmount > totalAmountIncludingFees && sweeping")
					}
					changeAmount = usingOutsAmount - totalAmountIncludingFees
					// for RCT we don't presently care about dustiness so add entire change amount
					DDLog.Info("HostedMonero", "Sending change of \(FormattedString(fromMoneroAmount: changeAmount)) to \(wallet__public_address!)")
				}
				//
				self.updateProcessStep(to: .fetchingDecoyOutputs)
				assert(self._current_request == nil)
				self._current_request = HostedMonero.APIClient.shared.RandomOuts(
					using_outs: usingOuts,
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
						__proceedTo_createSignedTxAndAttemptToSend(
							original_unusedOuts: original_unusedOuts,
							passedIn_attemptAt_network_minimumFee: this_attemptAt_network_minimumFee, // need to use the updated one
							usingOuts: usingOuts,
							mix_outs: result!.amount_outs,
							feePerKB: feePerKB,
							changeAmount: changeAmount
						)
					}
				)
			}
			func __proceedTo_createSignedTxAndAttemptToSend(
				original_unusedOuts: [MoneroOutputDescription],
				passedIn_attemptAt_network_minimumFee: MoneroAmount,
				usingOuts: [MoneroOutputDescription], // would be nice to try to avoid having to send these args through, but globals seem a more complex option
				mix_outs: [MoneroRandomAmountAndOutputs],
				feePerKB: MoneroAmount,
				changeAmount: MoneroAmount
			) {
				self.updateProcessStep(to: .constructingTransaction)
				assert(
					final__pid_encrypt == false || MoneroUtils.PaymentIDs.isAValid(paymentId: final__payment_id!, ofVariant: .short)
				)
				let (err_str, optl_serialized_signedTx, optl_tx_hash, optl_tx_key) = MyMoneroCore.shared_objCppBridge.new_serializedSignedTransaction(
					from_address: wallet__public_address,
					wallet__private_keys: wallet__private_keys,
					to_address: target_address,
					sending_amount: totalAmountWithoutFee.integerRepresentation, // this can get modified, i.e. on sweep
					fee_amount: passedIn_attemptAt_network_minimumFee.integerRepresentation,
					change_amount: changeAmount.integerRepresentation,
					payment_id: final__payment_id,
					usingOuts: usingOuts,
					randomOuts: mix_outs
				)
				if let err_str = err_str {
					self.failWithErr_fn?(err_str)
					return
				}
				let serialized_signedTx = optl_serialized_signedTx!
				let tx_hash = optl_tx_hash!
				let tx_key = optl_tx_key!
				//
				// work out per-kb fee for transaction and verify that it's enough
				let txBlobBytes = Double(serialized_signedTx.count) / 2.0
				var numKB = UInt(floor(txBlobBytes / 1024.0))
				if txBlobBytes.truncatingRemainder(dividingBy: 1024) != 0 { // TODO: AUDIT: != 0 correct here? note: truncatingRemainder is % operator
					numKB += 1
				}
				DDLog.Info("HostedMonero", "\(txBlobBytes) bytes <= \(numKB) KB (current fee: \(FormattedString(fromMoneroAmount: passedIn_attemptAt_network_minimumFee))")
				let feeActuallyNeededByNetwork = MoneroUtils.Fees.calculate_fee__kb(feePerKB, numKB, MoneroUtils.Fees.fee_multiplier_for_priority(self.priority))
				// if we need a higher fee
				if feeActuallyNeededByNetwork > passedIn_attemptAt_network_minimumFee {
					DDLog.Info("HostedMonero", "Need to reconstruct the tx with enough of a network fee. Previous fee: \(FormattedString(fromMoneroAmount: passedIn_attemptAt_network_minimumFee)) New fee: \(FormattedString(fromMoneroAmount: feeActuallyNeededByNetwork)))")
					__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
						original_unusedOuts: original_unusedOuts, // this must be the original unusedOuts
						feePerKB: feePerKB, // this could probably be cached on the instance if really desired..
						passedIn_attemptAt_network_minimumFee: feeActuallyNeededByNetwork
					)
					// ^-- we are re-entering this codepath after changing this feeActuallyNeededByNetwork
					return
				}
				//
				// generated with correct per-kb fee
				let final_networkFee = passedIn_attemptAt_network_minimumFee // just to make things clear
				DDLog.Info("HostedMonero", "Successful tx generation, submitting tx. Going with final_networkFee of \(FormattedString(fromMoneroAmount: final_networkFee))")
				//
				// status: submitting…
				assert(self._current_request == nil)
				self.updateProcessStep(to: .submittingTransaction)
				self._current_request = HostedMonero.APIClient.shared.SubmitSerializedSignedTransaction(
					address: self.wallet__public_address,
					view_key__private: self.wallet__private_keys.view,
					serializedSignedTx: serialized_signedTx,
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
						thisSelf.success_fn?(
							totalAmountWithoutFee,
							final__payment_id,
							tx_hash,
							final_networkFee,
							tx_key
						) // 🎉
					}
				)
//				preSuccess_obtainedSubmitTransactionRequestHandle(requestHandle)
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
