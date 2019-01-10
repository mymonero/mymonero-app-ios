//
//  MyMoneroCore_ObjCpp.mm
//  MyMonero
//
//  Created by Paul Shapiro on 11/22/17.
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
#import "MyMoneroCore_ObjCpp.h"
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
//
// Accessory types
@implementation Monero_DecodedAddress_RetVals
@end
//
@implementation Monero_Send_Step1_RetVals
@end
//
@implementation Monero_Send_Step2_RetVals
@end
//
@implementation Monero_Arg_SpendableOutput
@end
//
@implementation Monero_Arg_RandomAmountAndOuts
@end
//
@implementation Monero_Arg_RandomAmountOut
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

+ (nonnull Monero_Send_Step1_RetVals *)send_step1__prepare_params_for_get_decoysWithSweeping:(BOOL)sweeping
																			  sending_amount:(uint64_t)sending_amount
																				   fee_per_b:(uint64_t)fee_per_b
																					fee_mask:(uint64_t)fee_mask
																					priority:(uint32_t)priority
																			 unspent_outputs:(NSArray<Monero_Arg_SpendableOutput *> *)args_outputs
																		   payment_id_string:(nullable NSString *)payment_id_string
														 optl__passedIn_attemptAt_fee_string:(nullable NSString *)passedIn_attemptAt_fee_string
{
	Monero_Send_Step1_RetVals *retVals = [Monero_Send_Step1_RetVals new];
	vector<SpendableOutput> outputs;
	for (Monero_Arg_SpendableOutput *usingOut in args_outputs) {
		SpendableOutput output{};
		output.amount = usingOut.amount;
		output.public_key = string(usingOut.public_key.UTF8String);
		optional<string> rct = none;
		if (usingOut.rct) {
			rct = string(usingOut.rct.UTF8String);
		}
		output.rct = rct;
		output.global_index = usingOut.global_index;
		output.index = usingOut.index;
		output.tx_pub_key = string(usingOut.tx_pub_key.UTF8String);
		outputs.push_back(output);
	}
	optional<string> optl_pid = none;
	if (payment_id_string != nil) {
		optl_pid = std::string(payment_id_string.UTF8String);
	}
	optional<uint64_t> passedIn_attemptAt_fee = none;
	if (passedIn_attemptAt_fee_string != nil) {
		passedIn_attemptAt_fee = stoull(std::string(passedIn_attemptAt_fee_string.UTF8String));
	}
	//
	Send_Step1_RetVals call_retVals; // the C++ one
	monero_transfer_utils::send_step1__prepare_params_for_get_decoys(
		call_retVals,
		optl_pid,
		sending_amount,
		sweeping,
		priority,
		[] (uint8_t version, int64_t early_blocks) -> bool
		{
			return lightwallet_hardcoded__use_fork_rules(version, early_blocks);
		},
		outputs,
		fee_per_b,
		fee_mask,
		//
		passedIn_attemptAt_fee
	);
	if (call_retVals.errCode != noError) {
		if (call_retVals.errCode == needMoreMoneyThanFound) { // must rewrite err_msg for return in this special case
			retVals.reconstructErr_needMoreMoneyThanFound = true;
			retVals.spendable_balance = call_retVals.spendable_balance;
			retVals.required_balance = call_retVals.required_balance;
		} else {
			retVals.errStr_orNil = [NSString stringWithUTF8String:
				err_msg_from_err_code__create_transaction(call_retVals.errCode).c_str()
			];
		}
		return retVals;
	}
	NSMutableArray *retVals__outputs = [NSMutableArray new];
	{
		for (vector<SpendableOutput>::const_iterator it = call_retVals.using_outs.begin(); it != call_retVals.using_outs.end(); it++) {
			Monero_Arg_SpendableOutput *spendableOutput = [Monero_Arg_SpendableOutput new];
			spendableOutput.amount = (*it).amount;
			spendableOutput.public_key = [NSString stringWithUTF8String:(*it).public_key.c_str()];
			if ((*it).rct != none) {
				spendableOutput.rct = [NSString stringWithUTF8String:(*(*it).rct).c_str()];
			}
			spendableOutput.global_index = (*it).global_index;
			spendableOutput.index = (*it).index;
			spendableOutput.tx_pub_key = [NSString stringWithUTF8String:(*it).tx_pub_key.c_str()];
			[retVals__outputs addObject:spendableOutput];
		}
	}
	// TODO: need to return mixin here?
	retVals.using_outs = retVals__outputs;
	retVals.using_fee = call_retVals.using_fee;
	retVals.final_total_wo_fee = call_retVals.final_total_wo_fee;
	retVals.change_amount = call_retVals.change_amount;
	//
	return retVals;
}
+ (nonnull Monero_Send_Step2_RetVals *)send_step2__try_create_transactionWithNetType:(NetType)objcNetType
																 from_address_string:(NSString *)from_address_string
																  sec_viewKey_string:(NSString *)sec_viewKey_string
																 sec_spendKey_string:(NSString *)sec_spendKey_string
																   to_address_string:(NSString *)to_address_string
																   payment_id_string:(NSString *)payment_id_string
																  final_total_wo_fee:(uint64_t)final_total_wo_fee
																	   change_amount:(uint64_t)change_amount
																		   using_fee:(uint64_t)using_fee
																			priority:(uint32_t)priority
																		  using_outs:(NSArray<Monero_Arg_SpendableOutput *> *)args_using_outs
																			mix_outs:(NSArray<Monero_Arg_RandomAmountAndOuts *> *)args_mix_outs
																		   fee_per_b:(uint64_t)fee_per_b
																			fee_mask:(uint64_t)fee_mask
																		 unlock_time:(uint64_t)unlock_time
{
	Monero_Send_Step2_RetVals *retVals = [Monero_Send_Step2_RetVals new];
	vector<SpendableOutput> outputs;
	for (Monero_Arg_SpendableOutput *usingOut in args_using_outs) {
		SpendableOutput output{};
		output.amount = usingOut.amount;
		output.public_key = string(usingOut.public_key.UTF8String);
		optional<string> rct = none;
		if (usingOut.rct) {
			rct = string(usingOut.rct.UTF8String);
		}
		output.rct = rct;
		output.global_index = usingOut.global_index;
		output.index = usingOut.index;
		output.tx_pub_key = string(usingOut.tx_pub_key.UTF8String);
		outputs.push_back(output);
	}
	vector<RandomAmountOutputs> mix_outs;
	for (Monero_Arg_RandomAmountAndOuts *mixOutDesc in args_mix_outs) {
		auto amountAndOuts = RandomAmountOutputs{};
		amountAndOuts.amount = mixOutDesc.amount;
		for (Monero_Arg_RandomAmountOut *mixOutOutputDesc in mixOutDesc.outputs) {
			auto amountOutput = RandomAmountOutput{};
			amountOutput.global_index = mixOutOutputDesc.global_index;
			amountOutput.public_key = string(mixOutOutputDesc.public_key.UTF8String);
			optional<string> rct = none;
			if (mixOutOutputDesc.rct) {
				rct = string(mixOutOutputDesc.rct.UTF8String);
			}
			amountOutput.rct = rct;
			amountAndOuts.outputs.push_back(amountOutput);
		}
		mix_outs.push_back(amountAndOuts);
	}
	optional<string> optl_pid = none;
	if (payment_id_string != nil) {
		optl_pid = std::string(payment_id_string.UTF8String);
	}
	Send_Step2_RetVals call_retVals; // the C++ one
	monero_transfer_utils::send_step2__try_create_transaction(
		call_retVals,
		std::string(from_address_string.UTF8String),
		std::string(sec_viewKey_string.UTF8String),
		std::string(sec_spendKey_string.UTF8String),
		std::string(to_address_string.UTF8String),
		optl_pid,
		final_total_wo_fee,
		change_amount,
		using_fee,
		priority,
		outputs,
		fee_per_b,
		fee_mask,
		mix_outs,
		[] (uint8_t version, int64_t early_blocks) -> bool
		{
			return lightwallet_hardcoded__use_fork_rules(version, early_blocks);
		},
		unlock_time,
		nettype_from_objcType(objcNetType)
	);
	if (call_retVals.errCode != noError) {
		retVals.errStr_orNil = [NSString stringWithUTF8String:
			err_msg_from_err_code__create_transaction(call_retVals.errCode).c_str()
		];
		//
		return retVals;
	}
	bool tx_must_be_reconstructed = call_retVals.tx_must_be_reconstructed;
	retVals.tx_must_be_reconstructed = tx_must_be_reconstructed;
	if (tx_must_be_reconstructed) {
		retVals.fee_actually_needed = call_retVals.fee_actually_needed;
		//
		return retVals;
	}
	NSAssert(call_retVals.signed_serialized_tx_string != none, @"Not expecting no signed_serialized_tx_string given no error");
	retVals.serialized_signed_tx = [NSString stringWithUTF8String:
		(*call_retVals.signed_serialized_tx_string).c_str()
	];
	retVals.tx_hash = [NSString stringWithUTF8String:(*call_retVals.tx_hash_string).c_str()];
	retVals.tx_key = [NSString stringWithUTF8String:(*call_retVals.tx_key_string).c_str()];

	return retVals;
}

@end
