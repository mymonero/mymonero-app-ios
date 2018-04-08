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
struct HostedMonero_SendFunds
{
	static func estimatedRingCTSize(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		var size = 0
		size += numberOfOutputs * 6306
		size += ((mixin + 1) * 4 + 32 + 8) * numberOfInputs //key offsets + key image + amount
		size += 64 * (mixin + 1) * numberOfInputs + 64 * numberOfInputs //signature + pseudoOuts/cc
		size += 74 //extra + whatever, assume long payment ID
		//
		return size
	}
	static func estimatedRingCTSize_numKB(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		let numKB = Int(ceil(
			Double(estimatedRingCTSize(numberOfInputs, mixin, numberOfOutputs)) / 1024.0
		))
		//
		return numKB
	}
	static func estimatedRingCT_neededNetworkFee(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> MoneroAmount
	{
		let est_numKB = estimatedRingCTSize_numKB(numberOfInputs, mixin, numberOfOutputs)
		let est_amount = MoneroAmount("\(est_numKB)")! * MoneroConstants.feePerKB
		//
		return est_amount
	}
}
//
extension HostedMoneroAPIClient
{
	// TODO: port this to something akin to an OperationQueue so that it can be canceled properly
	
	
	static func SendFunds( // assumes isRingCT=true - not intended to support non-rct nor sweep_all-like txs
		target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
		amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
		wallet__public_address: MoneroAddress,
		wallet__private_keys: MoneroKeyDuo,
		wallet__public_keys: MoneroKeyDuo,
		hostedMoneroAPIClient: HostedMoneroAPIClient,
		payment_id: MoneroPaymentID?,
//		preSuccess_obtainedSubmitTransactionRequestHandle: @escaping (
//			_ requestHandle: HostedMoneroAPIClient.RequestHandle
//		) -> Void,
		success_fn: @escaping (
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount
		) -> Void,
		failWithErr_fn: @escaping (
			_ err_str: String
		) -> Void
	)
	{
		//
		// some callback trampoline func declarations…
		func __trampolineFor_success(
			tx_hash: MoneroTransactionHash,
			tx_fee: MoneroAmount
		) -> Void
		{
			success_fn(
				tx_hash,
				tx_fee
			)
		}
		func __trampolineFor_err_withStr(err_str: String) -> Void
		{
			DDLog.Error("HostedMonero", "SendFunds(): \(err_str)")
			failWithErr_fn(err_str)
		}
		// status: preparing to send funds…
		if amount <= 0 {
			__trampolineFor_err_withStr(err_str: "The amount you've entered is too low")
			return
		}
		let totalAmountWithoutFee = MoneroAmount.new(withDouble: amount)
		let targetDescription = SendFundsTargetDescription(
			address: target_address,
			amount: totalAmountWithoutFee
		)
	//	DDLog.Info("HostedMonero", "targetDescription \(targetDescription)")
		DDLog.Info("HostedMonero", "Total to send, before fee: \(totalAmountWithoutFee)")
		//
		// Derive/finalize some values…
		let final__mixin = MyMoneroCore.fixedMixin
		if final__mixin <= 0 { // TODO: min mixin checking
			__trampolineFor_err_withStr(err_str: "Expected mixin > 0")
			return
		}
		var final__payment_id = payment_id == "" ? nil : payment_id
		var final__pid_encrypt = false // we don't want to encrypt payment ID unless we find an integrated one (finalized just below)
		MyMoneroCore.shared.DecodeAddress(target_address)
		{ (err_str, decodedAddressComponents) in
			if let _ = err_str {
				__trampolineFor_err_withStr(err_str: "Invalid recipient address.")
				return
			}
			guard let decodedAddressComponents = decodedAddressComponents else {
				__trampolineFor_err_withStr(err_str: "Error obtaining decoded recipient Monero address components.")
				return
			}
			if decodedAddressComponents.intPaymentId != nil && payment_id != nil {
				__trampolineFor_err_withStr(err_str: "Payment ID field must be blank when using an Integrated Address")
				return
			}
			if decodedAddressComponents.intPaymentId != nil {
				final__payment_id = decodedAddressComponents.intPaymentId
				final__pid_encrypt = true // we do want to encrypt if using an integrated address
				assert(
					MoneroUtils.PaymentIDs.isAValid(
						paymentId: final__payment_id!,
						ofVariant: .short
					)
				)
			} else {
				if MoneroUtils.PaymentIDs.isAValidOrNotA(paymentId: final__payment_id) == false { // Validation
					__trampolineFor_err_withStr(err_str: "The payment ID you've entered is not valid")
					return
				}
				if final__payment_id != nil {
					final__pid_encrypt = MoneroUtils.PaymentIDs.isAValid(
						paymentId: final__payment_id!,
						ofVariant: .short // if it's a short pid, encrypt
					)
				}
			}
			_proceedTo_getUnspentOutsUsableForMixin()
		}
		func _proceedTo_getUnspentOutsUsableForMixin()
		{
			let _ = hostedMoneroAPIClient.UnspentOuts(
				address: wallet__public_address,
				view_key__private: wallet__private_keys.view,
				spend_key__public: wallet__public_keys.spend,
				spend_key__private: wallet__private_keys.spend,
				{ (err_str, result) in
					if let err_str = err_str {
						__trampolineFor_err_withStr(err_str: err_str)
						return
					}
					_proceedTo_constructTransferListAndSendFundsWithUnusedUnspentOuts(
						original_unusedOuts: result!.unusedOutputs
					)
				}
			)
		}
		func _proceedTo_constructTransferListAndSendFundsWithUnusedUnspentOuts(
			original_unusedOuts: [MoneroOutputDescription]
		)
		{ // status: constructing transaction…
			let feePerKB = MoneroConstants.feePerKB
			// Transaction will need at least 1KB fee (13KB for RingCT)
			let network_minimumTXSize_kb = 13 // because isRingCT=true
			let network_minimumFee = feePerKB * BigInt(network_minimumTXSize_kb)
			// ^-- now we're going to try using this minimum fee but the codepath has to be able to be re-entered if we find after constructing the whole tx that it is larger in kb than the minimum fee we're attempting to send it off with
			__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
				original_unusedOuts: original_unusedOuts,
				passedIn_attemptAt_network_minimumFee: network_minimumFee
			)
		}
		func __reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
			original_unusedOuts: [MoneroOutputDescription],
			passedIn_attemptAt_network_minimumFee: MoneroAmount
		)
		{ // Now we need to establish some values for balance validation and to construct the transaction
			DDLog.Info("HostedMonero", "Entered re-enterable tx building codepath with original_unusedOuts \(original_unusedOuts)")
			var attemptAt_network_minimumFee = passedIn_attemptAt_network_minimumFee // we may change this if isRingCT
			let _/*hostingService_chargeAmount*/ = HostedMoneroAPIClient_HostConfig.HostingServiceChargeForTransaction(
				with: attemptAt_network_minimumFee
			)
			var totalAmountIncludingFees = totalAmountWithoutFee + attemptAt_network_minimumFee/* + hostingService_chargeAmount NOTE service fee removed for now */
			let usableOutputsAndAmounts = _outputsAndAmountToUseForMixin(
				target_amount: totalAmountIncludingFees,
				unusedOuts: original_unusedOuts
			)
			
			DDLog.Info("HostedMonero", "usableOutputsAndAmounts \(usableOutputsAndAmounts)")
			
			// v-- now, since isRingCT=true, compute fee as closely as possible before hand
			var usingOuts = usableOutputsAndAmounts.usingOuts
			var usingOutsAmount = usableOutputsAndAmounts.usingOutsAmount
			var remaining_unusedOuts = usableOutputsAndAmounts.remaining_unusedOuts
			if usingOuts.count > 1 {
				var newNeededFee = HostedMonero_SendFunds.estimatedRingCT_neededNetworkFee(usingOuts.count, final__mixin, 2)
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
					newNeededFee = HostedMonero_SendFunds.estimatedRingCT_neededNetworkFee(usingOuts.count, final__mixin, 2)
					totalAmountIncludingFees = totalAmountWithoutFee + newNeededFee
				}
				DDLog.Info("HostedMonero", "New fee: \(FormattedString(fromMoneroAmount: newNeededFee)) for \(usingOuts.count) inputs")
				attemptAt_network_minimumFee = newNeededFee
			}
			DDLog.Info("HostedMonero", "~ Balance required: \(FormattedString(fromMoneroAmount: totalAmountIncludingFees))")
			// Now we can validate available balance with usingOutsAmount (TODO? maybe this check can be done before selecting outputs?)
			if usingOutsAmount < totalAmountIncludingFees {
				__trampolineFor_err_withStr(err_str:
					"Not enough spendable outputs / balance too low (have: \(FormattedString(fromMoneroAmount: usingOutsAmount)), need: \(FormattedString(fromMoneroAmount: totalAmountIncludingFees)))"
				)
				return
			}
			// Now we can put together the list of fund transfers we need to perform
			var fundTransferDescriptions: [SendFundsTargetDescription] = [] // to build…
			// I. the actual transaction the user is asking to do
			fundTransferDescriptions.append(
				SendFundsTargetDescription(
					address: target_address,
					amount: totalAmountWithoutFee
				)
			)
			// II. the fee that the hosting provider charges
			// NOTE: The fee has been removed for RCT until a later date
			// fundTransferDescriptions.push({
			//             address: hostedMoneroAPIClient.HostingServiceFeeDepositAddress(),
			//             amount: hostingService_chargeAmount
			// })
			// III. some amount of the total outputs will likely need to be returned to the user as "change":
			func ___proceed()
			{
				__proceedTo__getRandomOutsAndCreateTx(
					original_unusedOuts: original_unusedOuts,
					fundTransferDescriptions: fundTransferDescriptions,
					passedIn_attemptAt_network_minimumFee: attemptAt_network_minimumFee, // note: using actual local attemptAt_network_minimumFee
					usingOuts: usingOuts
				)
			}
			if usingOutsAmount > totalAmountIncludingFees {
				let changeAmount = usingOutsAmount - totalAmountIncludingFees
				DDLog.Info("HostedMonero", "changeAmount \(changeAmount)")
				// for RCT we don't presently care about dustiness so add entire change amount
				DDLog.Info("HostedMonero", "Sending change of \(FormattedString(fromMoneroAmount: changeAmount)) to \(wallet__public_address)")
				fundTransferDescriptions.append(
					SendFundsTargetDescription(
						address: wallet__public_address,
						amount: changeAmount
					)
				)
				___proceed()
				//
				return
			}
			if usingOutsAmount == totalAmountWithoutFee {
				// because isRingCT=true, create random destination to keep 2 outputs always in case of 0 change
				// TODO: would be nice to avoid this asynchrony so ___proceed() can be dispensed with
				MyMoneroCore.shared.New_FakeAddressForRCTTx({ (err_str, fakeAddress) in
					DDLog.Info("HostedMonero", "Sending 0 XMR to a fake address to keep tx uniform (no change exists): \(fakeAddress.debugDescription)")
					if let err_str = err_str {
						__trampolineFor_err_withStr(err_str: err_str)
						return
					}
					fundTransferDescriptions.append(
						SendFundsTargetDescription(
							address: fakeAddress!,
							amount: 0
						)
					)
					___proceed()
				})
				//
				return
			}
			___proceed()
		}
		func __proceedTo__getRandomOutsAndCreateTx(
			original_unusedOuts: [MoneroOutputDescription],
			fundTransferDescriptions: [SendFundsTargetDescription],
			passedIn_attemptAt_network_minimumFee: MoneroAmount,
			usingOuts: [MoneroOutputDescription]
		) {
			DDLog.Info("HostedMonero", "fundTransferDescriptions: \(fundTransferDescriptions)")
			// since final__mixin is always going to be > 0, since this function is not specced to support sweep_all…
			let _ = hostedMoneroAPIClient.RandomOuts(
				using_outs: usingOuts,
				{ (err_str, result) in
					if let err_str = err_str {
						__trampolineFor_err_withStr(err_str: err_str)
						return
					}
					__proceedTo_getViewKeyThenCreateTxAndAttemptToSend(
						original_unusedOuts: original_unusedOuts,
						fundTransferDescriptions: fundTransferDescriptions,
						passedIn_attemptAt_network_minimumFee: passedIn_attemptAt_network_minimumFee,
						usingOuts: usingOuts,
						mix_outs: result!.amount_outs
					)
				}
			)
		}
		func __proceedTo_getViewKeyThenCreateTxAndAttemptToSend(
			original_unusedOuts: [MoneroOutputDescription],
			fundTransferDescriptions: [SendFundsTargetDescription],
			passedIn_attemptAt_network_minimumFee: MoneroAmount,
			usingOuts: [MoneroOutputDescription], // would be nice to try to avoid having to send these args through, but globals seem a more complex option
			mix_outs: [MoneroRandomAmountAndOutputs]
		)
		{
			// Implementation note: per advice, in RingCT txs, decompose_tx_destinations should no longer necessary
			//
			func ___proceed(
				realDestViewKey: MoneroKey?
			)
			{
				__proceedTo_createTxAndAttemptToSend(
					original_unusedOuts: original_unusedOuts,
					fundTransferDescriptions: fundTransferDescriptions,
					passedIn_attemptAt_network_minimumFee: passedIn_attemptAt_network_minimumFee,
					usingOuts: usingOuts,
					mix_outs: mix_outs,
					realDestViewKey: realDestViewKey
				)
			}
			if final__pid_encrypt == true { // need to get viewkey for encrypting here, because of splitting and sorting
				MyMoneroCore.shared.DecodeAddress(target_address)
				{ (err_str, decodedAddressComponents) in
					if let _ = err_str {
						__trampolineFor_err_withStr(err_str: "Invalid recipient address.")
						return
					}
					guard let decodedAddressComponents = decodedAddressComponents else {
						__trampolineFor_err_withStr(err_str: "Error obtaining decoded recipient Monero address components while creating transaction.")
						return
					}
					let realDestViewKey = decodedAddressComponents.publicKeys.view
					DDLog.Info("HostedMonero", "got realDestViewKey \(realDestViewKey)")
					___proceed(realDestViewKey: realDestViewKey)
				}
				return
			}
			___proceed(realDestViewKey: nil)
		}
		func __proceedTo_createTxAndAttemptToSend(
			original_unusedOuts: [MoneroOutputDescription],
			fundTransferDescriptions: [SendFundsTargetDescription],
			passedIn_attemptAt_network_minimumFee: MoneroAmount,
			usingOuts: [MoneroOutputDescription], // would be nice to try to avoid having to send these args through, but globals seem a more complex option
			mix_outs: [MoneroRandomAmountAndOutputs],
			realDestViewKey: MoneroKey?
		)
		{
			assert(
				final__pid_encrypt == false
				|| (realDestViewKey != nil && MoneroUtils.PaymentIDs.isAValid(paymentId: final__payment_id!, ofVariant: .short))
			)
			MyMoneroCore.shared.CreateTransaction(
				wallet__public_keys: wallet__public_keys,
				wallet__private_keys: wallet__private_keys,
				splitDestinations: fundTransferDescriptions, // in RingCT=true, splitDestinations can equal fundTransferDescriptions
				usingOuts: usingOuts,
				mix_outs: mix_outs,
				fake_outputs_count: final__mixin,
				fee_amount: passedIn_attemptAt_network_minimumFee,
				payment_id: final__payment_id,
				pid_encrypt: final__pid_encrypt,
				ifPIDEncrypt_realDestViewKey: realDestViewKey,
				unlock_time: 0,
				isRingCT: true
			) { (err_str, signedTx) in
				if let err_str = err_str {
					__trampolineFor_err_withStr(err_str: err_str)
					return
				}
	//			DDLog.Info("HostedMonero", "signed tx: \(signedTx!)")
				__proceedTo_serializeSignedTxAndAttemptToSend(
					original_unusedOuts: original_unusedOuts,
					passedIn_attemptAt_network_minimumFee: passedIn_attemptAt_network_minimumFee,
					signedTx: signedTx!
				)
			}
		}
		func __proceedTo_serializeSignedTxAndAttemptToSend(
			original_unusedOuts: [MoneroOutputDescription],
			passedIn_attemptAt_network_minimumFee: MoneroAmount,
			signedTx: MoneroSignedTransaction
		)
		{
			MyMoneroCore.shared.SerializeTransaction(signedTx: signedTx)
			{ (err_str, serialized_signedTx, tx_hash) in
				if let err_str = err_str {
					__trampolineFor_err_withStr(err_str: err_str)
					return
				}
				let serialized_signedTx = serialized_signedTx!
				let tx_hash = tx_hash!
				//
				// work out per-kb fee for transaction and verify that it's enough
				let txBlobBytes = Double(serialized_signedTx.count) / 2.0
				var numKB = Int(floor(txBlobBytes / 1024.0))
				if txBlobBytes.truncatingRemainder(dividingBy: 1024) != 0 { // TODO: AUDIT: != 0 correct here? note: truncatingRemainder is % operator
					numKB += 1
				}
				DDLog.Info("HostedMonero", "\(txBlobBytes) bytes <= \(numKB) KB (current fee: \(FormattedString(fromMoneroAmount: passedIn_attemptAt_network_minimumFee))")
				let feeActuallyNeededByNetwork = MoneroConstants.feePerKB * MoneroAmount(numKB)
				// if we need a higher fee
				if feeActuallyNeededByNetwork > passedIn_attemptAt_network_minimumFee {
					DDLog.Info("HostedMonero", "Need to reconstruct the tx with enough of a network fee. Previous fee: \(FormattedString(fromMoneroAmount: passedIn_attemptAt_network_minimumFee)) New fee: \(FormattedString(fromMoneroAmount: feeActuallyNeededByNetwork)))")
					__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
						original_unusedOuts: original_unusedOuts, // this must be the original unusedOuts
						passedIn_attemptAt_network_minimumFee: feeActuallyNeededByNetwork
					)
					// ^-- we are re-entering this codepath after changing this feeActuallyNeededByNetwork
					return
				}
				//
				// generated with correct per-kb fee
				let final_networkFee = passedIn_attemptAt_network_minimumFee // just to make things clear
				DDLog.Info("HostedMonero", "Successful tx generation, submitting tx. Going with final_networkFee of \(FormattedString(fromMoneroAmount: final_networkFee))")
				// status: submitting…
				let _/*requestHandle*/ = hostedMoneroAPIClient.SubmitSerializedSignedTransaction(
					address: wallet__public_address,
					view_key__private: wallet__private_keys.view,
					serializedSignedTx: serialized_signedTx,
					{ (err_str, nilValue) in
						if let err_str = err_str {
							__trampolineFor_err_withStr(err_str: "Unexpected error while submitting your transaction: \(err_str)")
							return
						}
						let tx_fee = final_networkFee/* + hostingService_chargeAmount NOTE: Service charge removed to reduce bloat for now */
						__trampolineFor_success(
							tx_hash: tx_hash,
							tx_fee: tx_fee
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
		unusedOuts: [MoneroOutputDescription]
	) -> (
		usingOuts: [MoneroOutputDescription],
		usingOutsAmount: MoneroAmount,
		remaining_unusedOuts: [MoneroOutputDescription]
	)
	{
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
