//
//  MyMoneroCore_ObjCpp.mm
//  MyMonero
//
//  Created by Paul Shapiro on 11/22/17.
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
#import "MyMoneroCore_ObjCpp.h"
//
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
//
#include "cryptonote_basic_impl.h"
#include "string_tools.h"
using namespace epee;
using namespace std;
using namespace boost;
//
#include "monero_paymentID_utils.hpp"
#include "monero_wallet_utils.hpp"
#include "monero_transfer_utils.hpp"
#include "monero_key_image_utils.hpp"
#include "monero_fork_rules.hpp"
using namespace monero_fork_rules;
using namespace monero_transfer_utils;
#include "monero_send_routine.hpp"
using namespace monero_send_routine;
//
// Accessory types
@implementation Monero_DecodedAddress_RetVals
@end
//
//
cryptonote::network_type nettype_from_objcType(NetType nettype)
{
	switch (nettype) {
		case MM_MAINNET:
			return cryptonote::MAINNET;
		case MM_STAGENET:
			return cryptonote::STAGENET;
		case MM_TESTNET:
			return cryptonote::TESTNET;
		default:
			throw [NSException exceptionWithName:@"Illegal NetType" reason:@"Illegal NetType" userInfo:nil];
	}
}
//
// Constants
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_Low = 1;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedLow = 2;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_MedHigh = 3;
uint32_t const MyMoneroCore_ObjCpp_SimplePriority_High = 4;
//
// Principal type
@implementation MyMoneroCore_ObjCpp
//
// Class
+ (nonnull NSString *)retValDictKey__ErrStr
{
	return @"ErrStr";
}
+ (nonnull NSString *)retValDictKey__Value
{
	return @"Value";
}
//
// Accessors - Implementations
+ (BOOL)areEqualMnemonics:(nonnull NSString *)a b:(nonnull NSString *)b;
{
	return monero_wallet_utils::are_equal_mnemonics(
		std::string(a.UTF8String),
		std::string(b.UTF8String)
	);
}

+ (BOOL)newlyCreatedWallet:(nonnull NSString *)languageCode
				   nettype:(NetType)nettype
						fn:(void (^_Nonnull)
							(
							 NSString * _Nullable errStr_orNil,
							 // OR
							 // TODO: return a singular container object/struct which holds typed strings instead?
							 NSString * _Nullable seed_NSString,
							 NSString * _Nullable mnemonic_NSString,
							 NSString * _Nullable mnemonicLanguage_NSString,
							 NSString * _Nullable address_NSString,
							 NSString * _Nullable sec_viewKey_NSString,
							 NSString * _Nullable sec_spendKey_NSString,
							 NSString * _Nullable pub_viewKey_NSString,
							 NSString * _Nullable pub_spendKey_NSString
							 )
							)fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil
		   );
	};
	monero_wallet_utils::WalletDescriptionRetVals retVals;
	bool r = monero_wallet_utils::convenience__new_wallet_with_language_code(
		std::string(languageCode.UTF8String),
		retVals,
		nettype_from_objcType(nettype)
	);
	bool did_error = retVals.did_error;
	if (!r) {
		NSAssert(did_error, @"Illegal: fail flag but !did_error");
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.err_string).c_str()]);
		return NO;
	}
	NSAssert(!did_error, @"Illegal: success flag but did_error");
	//
	monero_wallet_utils::WalletDescription walletDescription = *(retVals.optl__desc);
	fn(
	   nil,
	   //
	   [NSString stringWithUTF8String:walletDescription.sec_seed_string.c_str()],
	   [NSString stringWithUTF8String:std::string(walletDescription.mnemonic_string.data(), walletDescription.mnemonic_string.size()).c_str()],
	   [NSString stringWithUTF8String:walletDescription.mnemonic_language.c_str()],
	   [NSString stringWithUTF8String:walletDescription.address_string.c_str()],
	   [NSString stringWithUTF8String:string_tools::pod_to_hex(walletDescription.sec_viewKey).c_str()],
	   [NSString stringWithUTF8String:string_tools::pod_to_hex(walletDescription.sec_spendKey).c_str()],
	   [NSString stringWithUTF8String:string_tools::pod_to_hex(walletDescription.pub_viewKey).c_str()],
	   [NSString stringWithUTF8String:string_tools::pod_to_hex(walletDescription.pub_spendKey).c_str()]
	   );
	return YES;
}
//
//
+ (nonnull NSDictionary *)mnemonicStringFromSeedHex:(nonnull NSString *)seed_NSString
								mnemonicWordsetName:(nonnull NSString *)wordsetName
{
	monero_wallet_utils::SeedDecodedMnemonic_RetVals retVals = monero_wallet_utils::mnemonic_string_from_seed_hex_string(
		std::string(seed_NSString.UTF8String),
		std::string(wordsetName.UTF8String)
	);
	if (retVals.err_string != none) {
		return @{
			[[self class] retValDictKey__ErrStr] : [NSString stringWithUTF8String:(*retVals.err_string).c_str()]
		};
	}
	return @{
		 [[self class] retValDictKey__Value]: [NSString stringWithUTF8String:
			std::string(
				(*retVals.mnemonic_string).data(),
				(*retVals.mnemonic_string).size()
			).c_str()
		 ]
	};
}
//
+ (BOOL)seedAndKeysFromMnemonic:(nonnull NSString *)mnemonic_NSString
						nettype:(NetType)nettype
							 fn:(void (^_Nonnull)
								 (
								  NSString * _Nullable errStr_orNil,
								  // OR
								  NSString * _Nullable seed_NSString,
								  NSString * _Nullable mnemonic_language_NSString,
								  NSString * _Nullable address_NSString,
								  NSString * _Nullable sec_viewKey_NSString,
								  NSString * _Nullable sec_spendKey_NSString,
								  NSString * _Nullable pub_viewKey_NSString,
								  NSString * _Nullable pub_spendKey_NSString
								  )
								 )fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil
		   );
	};
	std::string mnemonic_string = std::string(mnemonic_NSString.UTF8String);
	monero_wallet_utils::WalletDescriptionRetVals retVals;
	BOOL r = monero_wallet_utils::wallet_with(
		mnemonic_string,
		retVals,
		nettype_from_objcType(nettype)
	);
	bool did_error = retVals.did_error;
	if (!r) {
		NSAssert(did_error, @"Illegal: fail flag but !did_error");
		_doFn_withErrStr([NSString stringWithUTF8String:(*retVals.err_string).c_str()]);
		return NO;
	}
	NSAssert(!did_error, @"Illegal: success flag but did_error");
	//
	monero_wallet_utils::WalletDescription walletDescription = *(retVals.optl__desc);
	//
	//	std::string mnemonic_string = walletDescription.mnemonic_string;
	std::string address_string = walletDescription.address_string;
	std::string sec_viewKey_hexString = string_tools::pod_to_hex(walletDescription.sec_viewKey);
	std::string sec_spendKey_hexString = string_tools::pod_to_hex(walletDescription.sec_spendKey);
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(walletDescription.pub_viewKey);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(walletDescription.pub_spendKey);
	//
	NSString *seed_NSString = [NSString stringWithUTF8String:walletDescription.sec_seed_string.c_str()];
	// TODO? we could assert that the returned mnemonic is the same as the input one
	NSString *mnemonic_language_NSString = [NSString stringWithUTF8String:walletDescription.mnemonic_language.c_str()];
	NSString *address_NSString = [NSString stringWithUTF8String:address_string.c_str()];
	NSString *sec_viewKey_NSString = [NSString stringWithUTF8String:sec_viewKey_hexString.c_str()];
	NSString *sec_spendKey_NSString = [NSString stringWithUTF8String:sec_spendKey_hexString.c_str()];
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	//
	// TODO: handle and pass through returned error … such as upon illegal mnemonic_language
	//
	fn(
	   nil,
	   //
	   seed_NSString,
	   mnemonic_language_NSString,
	   address_NSString,
	   sec_viewKey_NSString,
	   sec_spendKey_NSString,
	   pub_viewKey_NSString,
	   pub_spendKey_NSString
	   );
	return YES;
}
//
+ (void)verifiedComponentsForOpeningExistingWalletWithAddress:(nonnull NSString *)address_NSString
												  sec_viewKey:(nonnull NSString *)sec_viewKey_NSString
								sec_spendKey_orNilForViewOnly:(nullable NSString *)sec_spendKey_NSString_orNil
											   sec_seed_orNil:(nullable NSString *)sec_seed_NSString_orNil
									 wasANewlyGeneratedWallet:(BOOL)wasANewlyGeneratedWallet
													  nettype:(NetType)nettype
														   fn:(void (^ _Nonnull)
															   (
																NSString * _Nullable errStr_orNil,
																// OR
																NSString * _Nullable seed_NSString_orNil,
																//
																NSString * _Nullable address_NSString,
																NSString * _Nullable sec_viewKey_NSString_orNil,
																NSString * _Nullable sec_spendKey_NSString,
																NSString * _Nullable pub_viewKey_NSString,
																NSString * _Nullable pub_spendKey_NSString,
																BOOL isInViewOnlyMode,
																BOOL isValid
																)
															   )fn
{
	void (^_doFn_withErrStr)(NSString *) = ^void(NSString *errStr)
	{
		fn(
		   errStr,
		   //
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   nil,
		   NO,
		   NO
		   );
	};
	optional<string> sec_spendKey_string = none;
	if (sec_spendKey_NSString_orNil) {
		sec_spendKey_string = std::string(sec_spendKey_NSString_orNil.UTF8String);
	}
	optional<string> sec_seed_string = none;
	if (sec_seed_NSString_orNil) {
		sec_seed_string = std::string(sec_seed_NSString_orNil.UTF8String);
	}
	monero_wallet_utils::WalletComponentsValidationResults retVals;
	BOOL didSucceed = monero_wallet_utils::validate_wallet_components_with(
		std::string(address_NSString.UTF8String),
		std::string(sec_viewKey_NSString.UTF8String),
		sec_spendKey_string,
		sec_seed_string,
		nettype_from_objcType(nettype),
		retVals
	);
	if (retVals.did_error) {
		NSString *errStr = [NSString stringWithUTF8String:(*retVals.err_string).c_str()];
		_doFn_withErrStr(errStr);
		return;
	}
	NSAssert(didSucceed, @"Found unexpectedly didSucceed=false without an error");
	NSAssert(retVals.isValid, @"Found unexpectedly invalid wallet components without an error");
	//
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:retVals.pub_viewKey_string.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:retVals.pub_spendKey_string.c_str()];
	BOOL isInViewOnlyMode = retVals.isInViewOnlyMode;
	BOOL isValid = retVals.isValid;
	fn(
	   nil,
	   //
	   sec_seed_NSString_orNil,
	   //
	   address_NSString,
	   sec_viewKey_NSString,
	   sec_spendKey_NSString_orNil,
	   pub_viewKey_NSString,
	   pub_spendKey_NSString,
	   isInViewOnlyMode,
	   isValid
   );
}
+ (nonnull Monero_DecodedAddress_RetVals *)decodedAddress:(nonnull NSString *)addressString netType:(NetType)netType
{
	Monero_DecodedAddress_RetVals *retVals = [Monero_DecodedAddress_RetVals new];
	//
	cryptonote::address_parse_info info;
	bool didSucceed = cryptonote::get_account_address_from_str(info, nettype_from_objcType(netType), std::string(addressString.UTF8String));
	if (didSucceed == false) {
		retVals.errStr_orNil = NSLocalizedString(@"Invalid address", nil);
		//
		return retVals;
	}
	cryptonote::account_public_address address = info.address;
	std::string pub_viewKey_hexString = string_tools::pod_to_hex(address.m_view_public_key);
	std::string pub_spendKey_hexString = string_tools::pod_to_hex(address.m_spend_public_key);
	//
	NSString *pub_viewKey_NSString = [NSString stringWithUTF8String:pub_viewKey_hexString.c_str()];
	NSString *pub_spendKey_NSString = [NSString stringWithUTF8String:pub_spendKey_hexString.c_str()];
	NSString *paymentID_NSString_orNil = nil;
	if (info.has_payment_id == true) {
		crypto::hash8 payment_id = info.payment_id;
		std::string payment_id_hexString = string_tools::pod_to_hex(payment_id);
		paymentID_NSString_orNil = [NSString stringWithUTF8String:payment_id_hexString.c_str()];
	}
	{
		retVals.pub_viewKey_NSString = pub_viewKey_NSString;
		retVals.pub_spendKey_NSString = pub_spendKey_NSString;
		retVals.paymentID_NSString_orNil = paymentID_NSString_orNil;
		retVals.isSubaddress = info.is_subaddress;
	}
	return retVals;
}
+ (BOOL)isSubAddress:(nonnull NSString *)addressString netType:(NetType)netType
{
	Monero_DecodedAddress_RetVals *retVals = [self decodedAddress:addressString netType:netType];
	//
	return retVals.isSubaddress;
}
+ (BOOL)isIntegratedAddress:(nonnull NSString *)addressString netType:(NetType)netType
{
	Monero_DecodedAddress_RetVals *retVals = [self decodedAddress:addressString netType:netType];
	//
	return retVals.paymentID_NSString_orNil != nil;
}

+ (nullable NSString *)new_integratedAddrFromStdAddr:(nonnull NSString *)std_address_NSString andShortPID:(nonnull NSString *)short_paymentID netType:(NetType)netType
{
	std::string payment_id__string = std::string(short_paymentID.UTF8String);
	crypto::hash8 payment_id_short;
	bool didParse = monero_paymentID_utils::parse_short_payment_id(payment_id__string, payment_id_short);
	if (!didParse) {
		return nil;
	}
	cryptonote::address_parse_info info;
	bool didSucceed = cryptonote::get_account_address_from_str(info, nettype_from_objcType(netType), std::string(std_address_NSString.UTF8String));
	if (didSucceed == false) {
		return nil;
	}
	if (info.is_subaddress) {
		NSString *msg = [NSString stringWithFormat:@"%@ must not be called with a subaddress", NSStringFromSelector(_cmd)];
		NSAssert(false, msg);
		[NSException raise:@"Illegal address value" format:@"%@", msg];
		//
		return nil;
	}
	if (info.has_payment_id != false) {
		// could even throw / fatalError here
		return nil; // that was not a std_address!
	}
	std::string int_address_string = cryptonote::get_account_integrated_address_as_str(
		nettype_from_objcType(netType),
		info.address,
		payment_id_short
	);
	NSString *int_address_NSString = [NSString stringWithUTF8String:int_address_string.c_str()];
	//
	return int_address_NSString;
}

+ (nullable NSString *)new_integratedAddrFromStdAddr:(nonnull NSString *)std_address_NSString andShortPID:(nonnull NSString *)short_paymentID // mainnet
{
	return [self
		new_integratedAddrFromStdAddr:std_address_NSString
		andShortPID:short_paymentID
		netType:MM_MAINNET];
}

+ (nonnull NSString *)new_short_plain_paymentID
{
	return [NSString stringWithUTF8String:string_tools::pod_to_hex(
		monero_paymentID_utils::new_short_plain_paymentID()
	).c_str()];
}

+ (uint64_t)estimatedTxNetworkFeeWithFeePerB:(uint64_t)fee_per_b
									 priority:(uint32_t)priority
{
	uint64_t estimated_fee = monero_fee_utils::estimated_tx_network_fee(
		fee_per_b,
		priority,
		[] (uint8_t version, int64_t early_blocks) -> bool
		{
			return lightwallet_hardcoded__use_fork_rules(version, early_blocks);
		}
	);
	return estimated_fee;
}
+ (uint32_t)fixedRingsize
{
	return monero_transfer_utils::fixed_ringsize();
}
+ (uint32_t)fixedMixinsize
{
	return monero_transfer_utils::fixed_mixinsize();
}

+ (uint32_t)default_priority
{
	return MyMoneroCore_ObjCpp_SimplePriority_Low;
}

+ (nullable NSString *)new_keyImageFrom_tx_pub_key:(nonnull NSString *)tx_pub_key_NSString
									  sec_spendKey:(nonnull NSString *)sec_spendKey_NSString
									   sec_viewKey:(nonnull NSString *)sec_viewKey_NSString
									  pub_spendKey:(nonnull NSString *)pub_spendKey_NSString
										 out_index:(uint64_t)out_index
{
	crypto::secret_key sec_viewKey{};
	crypto::secret_key sec_spendKey{};
	crypto::public_key pub_spendKey{};
	crypto::public_key tx_pub_key{};
	{ // Would be nice to find a way to avoid converting these back and forth
		bool r = false;
		r = string_tools::hex_to_pod(std::string(sec_viewKey_NSString.UTF8String), sec_viewKey);
		NSAssert(r, @"Invalid secret view key");
		r = string_tools::hex_to_pod(std::string(sec_spendKey_NSString.UTF8String), sec_spendKey);
		NSAssert(r, @"Invalid secret spend key");
		r = string_tools::hex_to_pod(std::string(pub_spendKey_NSString.UTF8String), pub_spendKey);
		NSAssert(r, @"Invalid public spend key");
		r = string_tools::hex_to_pod(std::string(tx_pub_key_NSString.UTF8String), tx_pub_key);
		NSAssert(r, @"Invalid tx pub key");
	}
	monero_key_image_utils::KeyImageRetVals retVals;
	{
		bool r = monero_key_image_utils::new__key_image(pub_spendKey, sec_spendKey, sec_viewKey, tx_pub_key, out_index, retVals);
		if (!r) {
			return nil; // TODO: return error string? (unwrap optional)
		}
	}
	std::string key_image_hex_string = string_tools::pod_to_hex(retVals.calculated_key_image);
	NSString *key_image_hex_NSString = [NSString stringWithUTF8String:key_image_hex_string.c_str()];
	//
	return key_image_hex_NSString;
}

+ (void)async__send_fundsFromAddressString:(nonnull NSString *)from_address_string
						sec_viewKey_string:(nonnull NSString *)sec_viewKey_string
					   sec_spendKey_string:(nonnull NSString *)sec_spendKey_string
					   pub_spendKey_string:(nonnull NSString *)pub_spendKey_string
						 to_address_string:(nonnull NSString *)to_address_string
						 payment_id_string:(nullable NSString *)payment_id_string
							sending_amount:(uint64_t)sending_amount
								  priority:(uint32_t)priority
							   is_sweeping:(BOOL)is_sweeping
					   get_unspent_outs_fn:(void(^ _Nonnull)(
															 NSString *_Nonnull req_params_str,
															 void(^ _Nonnull cb)(NSString *_Nullable errStr_orNil, NSString *_Nullable res_json_str)
															 ))get_unspent_outs_fn
						get_random_outs_fn:(void(^ _Nonnull)(
															 NSString *_Nonnull req_params_str,
															 void(^ _Nonnull cb)(NSString *_Nullable errStr_orNil, NSString *_Nullable res_json_str)
															 ))get_random_outs_fn
						  submit_raw_tx_fn:(void(^ _Nonnull)(
															 NSString *_Nonnull req_params_str,
															 void(^ _Nonnull cb)(NSString *_Nullable errStr_orNil, NSString *_Nullable res_json_str)
															 ))submit_raw_tx_fn
						  status_update_fn:(void(^ _Nonnull)(uint32_t code))status_update_fn
								  error_fn:(void(^ _Nonnull)(NSString *_Nonnull errStr))error_fn
								success_fn:(void(^ _Nonnull)(
															 uint64_t used_fee,
															 uint64_t total_sent,
															 size_t mixin,
															 NSString *_Nullable final_payment_id,
															 NSString *_Nonnull signed_serialized_tx_string,
															 NSString *_Nonnull tx_hash_string,
															 NSString *_Nonnull tx_key_string,
															 NSString *_Nonnull tx_pub_key_string
															 ))success_fn
{
	optional<string> optl__pid_std_string = none;
	if (payment_id_string) {
		optl__pid_std_string = std::string(payment_id_string.UTF8String);
	}
	Async_SendFunds_Args args =
	{
		std::string(from_address_string.UTF8String),
		std::string(sec_viewKey_string.UTF8String),
		std::string(sec_spendKey_string.UTF8String),
		std::string(pub_spendKey_string.UTF8String),
		std::string(to_address_string.UTF8String),
		optl__pid_std_string,
		sending_amount, // sending amount
		is_sweeping, // is sweeping
		priority, // priority
		[get_unspent_outs_fn, error_fn] ( // get_unspent_outs
			const LightwalletAPI_Req_GetUnspentOuts &req_params,
			api_fetch_cb_fn get_unspent_outs_fn__cb_fn
		) -> void {
			boost::property_tree::ptree req_params_root;
			req_params_root.put("address", req_params.address);
			req_params_root.put("view_key", req_params.view_key);
			req_params_root.put("amount", req_params.amount);
			req_params_root.put("dust_threshold", req_params.dust_threshold);
			req_params_root.put("use_dust", req_params.use_dust);
			req_params_root.put("mixin", req_params.mixin);
			stringstream req_params_ss;
			boost::property_tree::write_json(req_params_ss, req_params_root, false/*pretty*/);
			//
			get_unspent_outs_fn(
				[NSString stringWithUTF8String:req_params_ss.str().c_str()],
				^void(NSString *errStr_orNil, NSString *res_json_str)
				{
					if (errStr_orNil) {
						error_fn(errStr_orNil); // just redirect so consumer has one cb they can observe
						return;
					}
					boost::property_tree::ptree res;
					stringstream ss;
					ss << res_json_str;
					boost::property_tree::json_parser::read_json(ss, res);
					//
					get_unspent_outs_fn__cb_fn(res);
				}
			);
		},
		[get_random_outs_fn, error_fn] ( // get_random_outs_fn
			const LightwalletAPI_Req_GetRandomOuts &req_params,
			const api_fetch_cb_fn get_random_outs_fn__cb_fn
		) -> void {
			boost::property_tree::ptree req_params_root;
			boost::property_tree::ptree amounts_ptree;
			BOOST_FOREACH(const string &amount_string, req_params.amounts)
			{
				property_tree::ptree amount_child;
				amount_child.put("", amount_string);
				amounts_ptree.push_back(std::make_pair("", amount_child));
			}
			req_params_root.add_child("amounts", amounts_ptree);
			req_params_root.put("count", req_params.count);
			stringstream req_params_ss;
			boost::property_tree::write_json(req_params_ss, req_params_root, false/*pretty*/);
			//
			get_random_outs_fn(
				[NSString stringWithUTF8String:req_params_ss.str().c_str()],
				^void(NSString *errStr_orNil, NSString *res_json_str)
				{
					if (errStr_orNil) {
						error_fn(errStr_orNil); // just redirect so consumer has one cb they can observe
						return;
					}
					boost::property_tree::ptree res;
					stringstream ss;
					ss << res_json_str;
					boost::property_tree::json_parser::read_json(ss, res);
					//
					get_random_outs_fn__cb_fn(res);
				}
			);
		},
		[submit_raw_tx_fn, error_fn] ( // submit_raw_tx_fn
			const LightwalletAPI_Req_SubmitRawTx &req_params,
			const api_fetch_cb_fn submit_raw_tx_fn__cb_fn
		) -> void {
			boost::property_tree::ptree req_params_root;
			boost::property_tree::ptree amounts_ptree;
			req_params_root.put("address", std::move(req_params.address));
			req_params_root.put("view_key", std::move(req_params.view_key));
			req_params_root.put("tx", std::move(req_params.tx));
			stringstream req_params_ss;
			boost::property_tree::write_json(req_params_ss, req_params_root, false/*pretty*/);
			auto req_params_string = req_params_ss.str();
			//
			submit_raw_tx_fn(
				[NSString stringWithUTF8String:req_params_ss.str().c_str()],
				^void(NSString *errStr_orNil, NSString *res_json_str)
				{
					if (errStr_orNil) {
						error_fn(errStr_orNil); // just redirect so consumer has one cb they can observe
						return;
					}
					boost::property_tree::ptree res;
					stringstream ss;
					ss << res_json_str;
					boost::property_tree::json_parser::read_json(ss, res);
					//
					submit_raw_tx_fn__cb_fn(res);
				}
			);
		},
		[status_update_fn] ( // status update fn
			SendFunds_ProcessStep code
		) -> void {
			status_update_fn(code);
		},
		[error_fn] ( // error
			const SendFunds_Error_RetVals &err_retVals
		) -> void {
			if (err_retVals.explicit_errMsg != none) {
				error_fn([NSString stringWithUTF8String:(*(err_retVals.explicit_errMsg)).c_str()]);
			} else {
				// TODO: manually construct the reply to include spendable_balance and required_balance
				error_fn([NSString stringWithUTF8String:(err_msg_from_err_code__create_transaction(*(err_retVals.errCode))).c_str()]);
			}
		},
		[success_fn] ( // success
			const SendFunds_Success_RetVals &success_retVals
		) -> void {
			success_fn(
				success_retVals.used_fee,
				success_retVals.total_sent,
				success_retVals.mixin,
				success_retVals.final_payment_id == boost::none ? nil : [NSString stringWithUTF8String:(*(success_retVals.final_payment_id)).c_str()],
				[NSString stringWithUTF8String:success_retVals.signed_serialized_tx_string.c_str()],
				[NSString stringWithUTF8String:success_retVals.tx_hash_string.c_str()],
				[NSString stringWithUTF8String:success_retVals.tx_key_string.c_str()],
				[NSString stringWithUTF8String:success_retVals.tx_pub_key_string.c_str()]
			);
		},
		0,
		MAINNET // hardcoding MAINNET for now
	};
	async__send_funds(args);
}

@end
