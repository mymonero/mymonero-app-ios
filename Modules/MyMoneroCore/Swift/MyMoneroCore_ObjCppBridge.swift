//
//  MyMoneroCore.swift
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
//
// Interface - Singleton
extension MyMoneroCore
{
	static let shared_objCppBridge = MyMoneroCore.ObjCppBridge()
}
//
// Internal - Implementations
extension MyMoneroCore
{
	//
	//
	class ObjCppBridge
	{
		//
		// Internal - Lifecycle - Init
		required init() {}
		//
		// Accessors
		func NewlyCreatedWallet(
			_ localeCode: String,
			_ fn: @escaping (_ err_str: String?, MoneroWalletDescription?) -> Void
		) {
			let _ = MyMoneroCore_ObjCpp.newlyCreatedWallet(
				localeCode,
				nettype: MM_MAINNET
			) { [weak self] (
				errStr_orNil,
				//
				// TODO: slightly more difficult to maintain; Might be nice to transition this an object which holds (typed) strings… but is it desirable to declare it in ObjC land?
				seed_hexString,
				mnemonic,
				mnemonicLanguage,
				address,
				sec_viewKey,
				sec_spendKey,
				pub_viewKey,
				pub_spendKey
			) in
				guard let _ = self else {
					return
				}
				if let errStr = errStr_orNil {
					fn(errStr, nil)
					return
				}
				let publicKeys = MoneroKeyDuo(
					view: pub_viewKey!,
					spend: pub_spendKey!
				)
				let privateKeys = MoneroKeyDuo(
					view: sec_viewKey!,
					spend: sec_spendKey!
				)
				let description = MoneroWalletDescription(
					mnemonic: mnemonic!,
					mnemonicLanguage: mnemonicLanguage! as MoneroMnemonicWordsetName,
					seed: seed_hexString!,
					publicAddress: address!,
					publicKeys: publicKeys,
					privateKeys: privateKeys
				)
				fn(nil, description)
			}
		}
		func MnemonicStringFromSeed(
			_ account_seed: String,
			_ wordsetName: MoneroMnemonicWordsetName
		) -> (
			err_str: String?,
			mnemonicString: MoneroSeedAsMnemonic?
		) {
			let retVals = MyMoneroCore_ObjCpp.mnemonicString(
				fromSeedHex: account_seed.objcSerialized, // really just returns the seed again
				mnemonicWordsetName: wordsetName.apiSafeMnemonicLanguage
			)
			let errStr_orNil = retVals[MyMoneroCore_ObjCpp.retValDictKey__ErrStr()] as? String
			let mnemonicString_orNil = retVals[MyMoneroCore_ObjCpp.retValDictKey__Value()] as? MoneroSeedAsMnemonic
			//
			return (errStr_orNil, mnemonicString_orNil)
		}
		func WalletDescriptionFromMnemonicSeed(
			_ mnemonicString: MoneroSeedAsMnemonic,
			_ fn: @escaping (_ err_str: String?, MoneroWalletDescription?) -> Void
		) {
			let _ = MyMoneroCore_ObjCpp.seedAndKeys(
				fromMnemonic: mnemonicString.objcSerialized,
				nettype: MM_MAINNET
			) { [weak self] (
				errStr_orNil,
				//
				// TODO: slightly more difficult to maintain; Might be nice to transition this an object which holds (typed) strings… but is it desirable to declare it in ObjC land?
				seed_hexString,
				mnemonicLanguage,
				address,
				sec_viewKey,
				sec_spendKey,
				pub_viewKey,
				pub_spendKey
			) in
				guard let _ = self else {
					return
				}
				if let errStr = errStr_orNil {
					fn(errStr, nil)
					return
				}
				let publicKeys = MoneroKeyDuo(
					view: pub_viewKey!,
					spend: pub_spendKey!
				)
				let privateKeys = MoneroKeyDuo(
					view: sec_viewKey!,
					spend: sec_spendKey!
				)
				let description = MoneroWalletDescription(
					mnemonic: mnemonicString,
					mnemonicLanguage: mnemonicLanguage! as MoneroMnemonicWordsetName,
					seed: seed_hexString!,
					publicAddress: address!,
					publicKeys: publicKeys,
					privateKeys: privateKeys
				)
				fn(nil, description)
			}
		}
		func New_VerifiedComponentsForLogIn(
			_ address: MoneroAddress,
			_ view_key: MoneroKey,
			spend_key: MoneroKey,
			seed_orNil: MoneroSeed?,
			wasAGeneratedWallet: Bool,
			_ fn: @escaping (
				_ err_str: String?,
				_ components: MoneroVerifiedComponentsForLogIn?
			) -> Void
		) {
			MyMoneroCore_ObjCpp.verifiedComponentsForOpeningExistingWallet(
				withAddress: address.objcSerialized,
				sec_viewKey: view_key.objcSerialized,
				sec_spendKey_orNilForViewOnly: spend_key.objcSerialized, // not going to be nil, here
				sec_seed_orNil: seed_orNil?.objcSerialized,
				wasANewlyGeneratedWallet: wasAGeneratedWallet,
				nettype: MM_MAINNET // Testnet etc could be exposed
			) { [weak self] (
				errStr_orNil,
				//
				seed_NSString_orNil,
				//
				address,
				sec_viewKey,
				sec_spendKey_orNil,
				pub_viewKey,
				pub_spendKey,
				isInViewOnlyMode,
				isValid
			) in
				guard let _ = self else {
					return
				}
				if let errStr = errStr_orNil {
					fn(errStr, nil)
					return
				}
				assert(isValid)
				let publicKeys = MoneroKeyDuo(
					view: pub_viewKey!,
					spend: pub_spendKey!
				)
				let privateKeys = MoneroKeyDuo(
					view: sec_viewKey!,
					spend: sec_spendKey_orNil! // will assume it exists since we passed it in and know we did not get a validation error
				)
				let components = MoneroVerifiedComponentsForLogIn(
					seed: seed_NSString_orNil,
					publicAddress: address!,
					publicKeys: publicKeys,
					privateKeys: privateKeys,
					isInViewOnlyMode: isInViewOnlyMode
				)
				fn(nil, components)
			}
		}
		func decoded(
			address: MoneroAddress
		) -> (
			err_str: String?,
			decodedAddressComponents: MoneroDecodedAddressComponents?
		) {
			let retVals = MyMoneroCore_ObjCpp.decodedAddress(
				address.objcSerialized,
				netType: MM_MAINNET
			)
			if let errStr = retVals.errStr_orNil {
				return (errStr, nil)
			}
			var paymentID_NSString_orNil = retVals.paymentID_NSString_orNil
			if paymentID_NSString_orNil == "" {
				paymentID_NSString_orNil = nil // normalize / sanitize
			}
			let keypair = MoneroKeyDuo(
				view: retVals.pub_viewKey_NSString!,
				spend: retVals.pub_spendKey_NSString!
			)
			let components = MoneroDecodedAddressComponents(
				publicKeys: keypair,
				intPaymentId: paymentID_NSString_orNil,
				isSubaddress: retVals.isSubaddress
			)
			return (nil, components)
		}
		func isSubAddress(_ string: MoneroAddress) -> Bool
		{
			return MyMoneroCore_ObjCpp.isSubAddress(string, netType: MM_MAINNET)
		}
		func isIntegratedAddress(_ string: MoneroAddress) -> Bool
		{
			return MyMoneroCore_ObjCpp.isIntegratedAddress(string, netType: MM_MAINNET)
		}
		func New_IntegratedAddress(
			fromStandardAddress standardAddress: MoneroStandardAddress,
			short_paymentID: MoneroShortPaymentID
		) -> MoneroIntegratedAddress? {
			return MyMoneroCore_ObjCpp.new_integratedAddr(
				fromStdAddr: standardAddress,
				andShortPID: short_paymentID
			)
		}
		var New_PaymentID: MoneroShortPaymentID {
			return MyMoneroCore_ObjCpp.new_short_plain_paymentID()
		}
		static var fixedRingsize: UInt32 {
			return MyMoneroCore_ObjCpp.fixedRingsize()
		}
		static var fixedMixinsize: UInt32 {
			return MyMoneroCore_ObjCpp.fixedMixinsize()
		}
		static func estimatedNetworkFee(
			withFeePerB fee_per_b: MoneroAmount,
			priority: MoneroTransferSimplifiedPriority = .low
		) -> MoneroAmount {
			let estimatedFee_UInt64 = MyMoneroCore_ObjCpp.estimatedTxNetworkFee(
				withFeePerB: UInt64(String(fee_per_b))!,
				priority: priority.cppRepresentation
			)
			return MoneroAmount("\(estimatedFee_UInt64)")!
		}
		func areEqualMnemonics(_ a: String, _ b: String) -> Bool
		{
			return MyMoneroCore_ObjCpp.areEqualMnemonics(a, b: b)
		}
		func new__key_image_from(
			tx_pub_key: MoneroTransactionPubKey,
			out_index: UInt64,
			public_address: MoneroAddress,
			sec_keys: MoneroKeyDuo,
			pub_spendKey: MoneroKey
		) -> MoneroKeyImage {
			return MyMoneroCore_ObjCpp.new_keyImage(
				from_tx_pub_key: tx_pub_key,
				sec_spendKey: sec_keys.spend,
				sec_viewKey: sec_keys.view,
				pub_spendKey: pub_spendKey,
				out_index: out_index
			)!
		}
		//
		func async__send_funds(
			from_address_string: String,
			sec_viewKey_string: MoneroKey,
			sec_spendKey_string: MoneroKey,
			pub_spendKey_string: MoneroKey,
			to_address_string: MoneroAddress,
			payment_id_string: MoneroPaymentID?,
			sending_amount: UInt64,
			priority: UInt32,
			is_sweeping: Bool,
			get_unspent_outs_fn: @escaping (
				_ req_params_str: String,
				_ cb: @escaping (_ err_str: String?, _ res_json_str: String?) -> Void
			) -> Void,
			get_random_outs_fn: @escaping (
				_ req_params_str: String,
				_ cb: @escaping (_ err_str: String?, _ res_json_str: String?) -> Void
			) -> Void,
			submit_raw_tx_fn: @escaping (
				_ req_params_str: String,
				_ cb: @escaping (_ err_str: String?, _ res_json_str: String?) -> Void
			) -> Void,
			status_update_fn: @escaping (_ code: UInt32) -> Void,
			error_fn: @escaping (_ err_str: String) -> Void,
			success_fn: @escaping (
				_ used_fee: UInt64,
				_ total_sent: UInt64,
				_ mixin: Int, // should be UInt32 but objc block requires Int, which seems fine here
				_ final_payment_id: String?,
				_ signed_serialized_tx_string: String,
				_ tx_hash_string: String,
				_ tx_key_string: String,
				_ tx_pub_key_string: String
			) -> Void
		) {
			MyMoneroCore_ObjCpp.async__send_funds(
				fromAddressString: from_address_string,
				sec_viewKey_string: sec_viewKey_string,
				sec_spendKey_string: sec_spendKey_string,
				pub_spendKey_string: pub_spendKey_string,
				to_address_string: to_address_string,
				payment_id_string: payment_id_string,
				sending_amount: sending_amount,
				priority: priority,
				is_sweeping: is_sweeping,
				get_unspent_outs_fn: get_unspent_outs_fn,
				get_random_outs_fn: get_random_outs_fn,
				submit_raw_tx_fn: submit_raw_tx_fn,
				status_update_fn: status_update_fn,
				error_fn: error_fn,
				success_fn: success_fn
			)
			// TODO sometime
//			if retVals.reconstructErr_needMoreMoneyThanFound { // must rewrite this error in this special case
//				retVals.errStr_orNil = String(format:
//					NSLocalizedString("Spendable balance too low. Have %@ %@; need %@ %@.", comment: ""),
//											  FormattedString(fromMoneroAmount: MoneroAmount("\(retVals.spendable_balance)")!),
//											  MoneroConstants.currency_symbol,
//											  FormattedString(fromMoneroAmount: MoneroAmount("\(retVals.required_balance)")!),
//											  MoneroConstants.currency_symbol
//				);
//			}
		}
	}
}

