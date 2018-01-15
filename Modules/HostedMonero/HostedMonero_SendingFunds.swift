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
	static func estimatedRingCTSize(
		_ numberOfInputs: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		let Int__ringsize = Int(MyMoneroCore.shared.fixedRingsize)
		var size = 0
		size += numberOfOutputs * 6306
		size += (Int__ringsize * 4 + 32 + 8) * numberOfInputs //key offsets + key image + amount
		size += 64 * Int__ringsize * numberOfInputs + 64 * numberOfInputs //signature + pseudoOuts/cc
		size += 74 //extra + whatever, assume long payment ID
		//
		return size
	}
	static func estimatedRingCTSize_numKB(
		_ numberOfInputs: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		let numKB = Int(ceil(
			Double(estimatedRingCTSize(numberOfInputs, numberOfOutputs)) / 1024.0
		))
		//
		return numKB
	}
	static func estimatedRingCT_neededNetworkFee(
		_ numberOfInputs: Int,
		_ numberOfOutputs: Int
	) -> MoneroAmount
	{
		let est_numKB = estimatedRingCTSize_numKB(numberOfInputs, numberOfOutputs)
		let est_amount = MoneroAmount("\(est_numKB)")! * MoneroConstants.feePerKB
		//
		return est_amount
	}
}
//
extension HostedMonero
{
	class FundsSender
	{
		var hasSendBeenInitiated: Bool = false
		//
		var target_address: MoneroAddress! // currency-ready wallet address, but not an OA address (resolve before calling)
		var amount: HumanUnderstandableCurrencyAmountDouble! // human-understandable number, e.g. input 0.5 for 0.5 XMR
		var wallet__keyImageCache: MoneroUtils.KeyImageCache!
		var wallet__public_address: MoneroAddress!
		var wallet__private_keys: MoneroKeyDuo!
		var wallet__public_keys: MoneroKeyDuo!
		var wallet__blockchainSize: UInt64!
		var priority: MoneroTransferSimplifiedPriority
		var payment_id: MoneroPaymentID?
		// TODO: for cancelling?
//		var preSuccess_obtainedSubmitTransactionRequestHandle: (
//			_ requestHandle: APIClient.RequestHandle
//		) -> Void
		var success_fn: ((
			_ tx_hash: MoneroTransactionHash,
			_ tx_fee: MoneroAmount
		) -> Void)?
		var failWithErr_fn: ((
			_ err_str: String
		) -> Void)?
		//
		init(
			target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
			amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
			wallet__keyImageCache: MoneroUtils.KeyImageCache,
			wallet__public_address: MoneroAddress,
			wallet__private_keys: MoneroKeyDuo,
			wallet__public_keys: MoneroKeyDuo,
			wallet__blockchainSize: UInt64,
			priority: MoneroTransferSimplifiedPriority,
			payment_id: MoneroPaymentID?
		) {
			self.target_address = target_address
			self.amount = amount
			self.wallet__keyImageCache = wallet__keyImageCache
			self.wallet__public_address = wallet__public_address
			self.wallet__private_keys = wallet__private_keys
			self.wallet__public_keys = wallet__public_keys
			self.wallet__blockchainSize = wallet__blockchainSize
			self.priority = priority
			self.payment_id = payment_id
		}
		func send()
		{
			assert(self.hasSendBeenInitiated == false)
			//
			// some callback trampoline func declarations…
			func __trampolineFor_err_withStr(err_str: String) -> Void
			{
				DDLog.Error("HostedMonero", "SendFunds(): \(err_str)")
				self.failWithErr_fn?(err_str)
			}
			// status: preparing to send funds…
			if amount <= 0 {
				__trampolineFor_err_withStr(err_str: "The amount you've entered is too low")
				return
			}
			//
			// Final derivations, validations…
			var final__payment_id = payment_id == "" ? nil : payment_id
			var final__pid_encrypt = false // we don't want to encrypt payment ID unless we find an integrated one (finalized just below)
			let (err_str, decodedAddressComponents_orNil) = MyMoneroCore.shared.decoded(address: target_address)
			if err_str != nil {
				__trampolineFor_err_withStr(err_str: "Invalid recipient address.")
				return
			}
			guard let decodedAddressComponents = decodedAddressComponents_orNil else {
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
			// TODO hang onto this to make it cancelable
			let _ = HostedMonero.APIClient.shared.UnspentOuts(
				wallet_keyImageCache: wallet__keyImageCache,
				address: wallet__public_address,
				view_key__private: wallet__private_keys.view,
				spend_key__public: wallet__public_keys.spend,
				spend_key__private: wallet__private_keys.spend,
				{ (err_str, result) in
					if let err_str = err_str {
						__trampolineFor_err_withStr(err_str: err_str)
						return
					}
					_proceedTo_contructAndSignTx(
						unusedOuts: result!.unspentOutputs
					)
				}
			)
			func _proceedTo_contructAndSignTx(
				unusedOuts: [MoneroOutputDescription]
			) {
				MyMoneroCore.shared.new_serializedSignedTransaction(
					wallet__private_keys: wallet__private_keys,
					to_address: target_address,
					amount_float_string: "\(amount!)", // the C++ code wants to parse the float string again; Must unwrap to prevent 'Optional(…)'
					payment_id: payment_id,
					blockchainSize: self.wallet__blockchainSize,
					priority: self.priority,
					unusedOuts: unusedOuts,
					getRandomOuts__block:
					{ (cb) in
						let retVals = Monero_GetRandomOutsBlock_RetVals()
						retVals.errStr_orNil = nil // TODO
						retVals.mixOuts = [[String: Any]]() // TODO
						
						cb(retVals)
					}
				) { (err_str, serializedSignedTransaction) in
					if let err_str = err_str {
						__trampolineFor_err_withStr(err_str: err_str)
						return
					}
					_proceedTo_submitSignedTx(
						serializedSignedTransaction: serializedSignedTransaction!
					)
				}
			}
			func _proceedTo_submitSignedTx(
				serializedSignedTransaction: MoneroSerializedSignedTransaction // TODO convert this to a bridge obj - it's just a string
			) {
				
				
				//			signedTx: MoneroSignedTransaction
				// TODO do we need MoneroSignedTransaction anymore?
				
				let serialized_signedTx: MoneroSerializedSignedTransaction = "" // TODO
				let tx_hash: MoneroTransactionHash = "" // TODO
				let final_networkFee = MoneroAmount("0")! // TODO
				//
				// generated with correct per-kb fee
				DDLog.Info("HostedMonero", "Successful tx generation, submitting tx. Going with final_networkFee of \(FormattedString(fromMoneroAmount: final_networkFee))")
				
				
				
				// TODO
				// TODO: set status: submitting…
				//			let _/*requestHandle*/ = HostedMonero.APIClient.SubmitSerializedSignedTransaction(
				//				address: wallet__public_address,
				//				view_key__private: wallet__private_keys.view,
				//				serializedSignedTx: serialized_signedTx,
				//				{ (err_str, nilValue) in
				//					if let err_str = err_str {
				//						__trampolineFor_err_withStr(err_str: "Unexpected error while submitting your transaction: \(err_str)")
				//						return
				//					}
				//					let tx_fee = final_networkFee/* + hostingService_chargeAmount NOTE: Service charge removed to reduce bloat for now */
				//						self.success_fn?(
				//							tx_hash,
				//							tx_fee
				//						) // 🎉
				//				}
				//			)
				//			preSuccess_obtainedSubmitTransactionRequestHandle(requestHandle)
			}
		}
	}
	//
	
}
