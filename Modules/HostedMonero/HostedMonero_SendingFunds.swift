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
		enum ProcessStep: Int
		{
			case none = 99999
			case fetchingLatestBalance = 1
			case calculatingFee = 2
			case fetchingDecoyOutputs = 3
			case constructingTransaction = 4 // may go back to .calculatingFee
			case submittingTransaction = 5
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
			assert(self._current_request == nil)
			self.hasSendBeenInitiated = true
			if !self.isSweeping && self.amount_orNilIfSweeping! <= 0 {
				self.failWithErr_fn?(NSLocalizedString("The amount you've entered is too low", comment: ""))
				return
			}
			MyMoneroCore.shared_objCppBridge.async__send_funds(
				from_address_string: wallet__public_address,
				sec_viewKey_string: wallet__private_keys.view,
				sec_spendKey_string: wallet__private_keys.spend,
				pub_spendKey_string: wallet__public_keys.spend,
				to_address_string: target_address,
				payment_id_string: payment_id == "" ? nil : payment_id,
				sending_amount: MoneroAmount.new(withDouble: self.isSweeping ? 0 : self.amount_orNilIfSweeping!).integerRepresentation, // this will get reassigned below if sweeping, so it's a var
				priority: priority.cppRepresentation,
				is_sweeping: isSweeping,
				get_unspent_outs_fn: { [weak self] (req_params_json_str, cb) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf.isCanceled {
						return
					}
					let req_params_data = req_params_json_str.data(using: .utf8)!
					var req_params: [String: Any]
					do {
						req_params = try JSONSerialization.jsonObject(with: req_params_data) as! [String: Any]
					} catch (let e) {
						thisSelf.failWithErr_fn?(e.localizedDescription)
						return
					}
					assert(thisSelf._current_request == nil)
					// modify params to convert bridge-strings to native primitives
					req_params["use_dust"] = NSString(string: req_params["use_dust"] as! String).boolValue
					req_params["mixin"] = Int(req_params["mixin"] as! String)
					thisSelf._current_request = HostedMonero.APIClient.shared.UnspentOuts(
						req_params: req_params,
						{ [weak self] (err_str, res_dict) in
							guard let thisSelf = self else {
								return
							}
							thisSelf._current_request = nil
							if thisSelf.isCanceled {
								return
							}
							if let err_str = err_str {
								cb(err_str, nil)
								return
							}
							var res_data: Data!
							do {
								res_data = try JSONSerialization.data(withJSONObject: res_dict!, options: [])
							} catch (let e) {
								thisSelf.failWithErr_fn?(e.localizedDescription)
								return
							}
							let res_json_str = String(data: res_data, encoding: .utf8)!
							cb(nil, res_json_str)
						}
					)
				},
				get_random_outs_fn: { [weak self] (req_params_json_str, cb) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf.isCanceled {
						return
					}
					let req_params_data = req_params_json_str.data(using: .utf8)!
					var req_params: [String: Any]
					do {
						req_params = try JSONSerialization.jsonObject(with: req_params_data) as! [String: Any]
					} catch (let e) {
						thisSelf.failWithErr_fn?(e.localizedDescription)
						return
					}
					assert(thisSelf._current_request == nil)
					// modify params to convert bridge-strings to native primitives
					req_params["count"] = Int(req_params["count"] as! String)
					//
					thisSelf._current_request = HostedMonero.APIClient.shared.RandomOuts(
						req_params: req_params,
						{ [weak self] (err_str, res_dict) in
							guard let thisSelf = self else {
								return
							}
							thisSelf._current_request = nil
							if thisSelf.isCanceled {
								return
							}
							if let err_str = err_str {
								cb(err_str, nil)
								return
							}
							var res_data: Data!
							do {
								res_data = try JSONSerialization.data(withJSONObject: res_dict!, options: [])
							} catch (let e) {
								thisSelf.failWithErr_fn?(e.localizedDescription)
								return
							}
							let res_json_str = String(data: res_data, encoding: .utf8)!
							cb(nil, res_json_str)
						}
					)
				},
				submit_raw_tx_fn: { [weak self] (req_params_json_str, cb) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf.isCanceled {
						return
					}
					let req_params_data = req_params_json_str.data(using: .utf8)!
					var req_params: [String: Any]
					do {
						req_params = try JSONSerialization.jsonObject(with: req_params_data) as! [String: Any]
					} catch (let e) {
						thisSelf.failWithErr_fn?(e.localizedDescription)
						return
					}
					assert(thisSelf._current_request == nil)
					thisSelf._current_request = HostedMonero.APIClient.shared.SubmitSerializedSignedTransaction(
						req_params: req_params,
						{ [weak self] (err_str, res) in
							guard let thisSelf = self else {
								return
							}
							thisSelf._current_request = nil
							if thisSelf.isCanceled {
								return
							}
							if let err_str = err_str {
								cb(err_str, nil)
								return
							}
							cb(nil, "{}"/*expecting empty reply anyway*/)
						}
					)
				},
				status_update_fn: { [weak self] (code) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf.isCanceled {
						return
					}
					thisSelf.updateProcessStep(to: ProcessStep(rawValue: Int(code))!)
				},
				error_fn: { [weak self] (err_str) in
					guard let thisSelf = self else {
						return
					}
					if thisSelf.isCanceled {
						return
					}
					thisSelf.failWithErr_fn?(err_str)
			}) { [weak self] (used_fee, total_sent, mixin, final_payment_id, signed_serialized_tx_string, tx_hash_string, tx_key_string, tx_pub_key_string) in
				guard let thisSelf = self else {
					return
				}
				if thisSelf.isCanceled {
					return
				}
				thisSelf.success_fn?(
					MoneroAmount("\(total_sent)")!,
					final_payment_id,
					tx_hash_string,
					MoneroAmount("\(used_fee)")!,
					tx_key_string
				) // 🎉
			}
		}
	}
}
