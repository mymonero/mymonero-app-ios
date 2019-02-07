//
//  SendFundsFormSubmissionHandle.h
//  MyMonero
//
//  Created by Paul Shapiro on 2/4/19.
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

#import <Foundation/Foundation.h>
#import "MyMoneroCore_ObjCpp.h"

typedef void (^SendFundsForm_StatusUpdateFn)(int code); // SendFunds::ProcessStep
typedef void (^SendFundsForm_RequestCallFn)(NSString *_Nonnull req_params_json_string);
typedef void (^SendFundsForm_ErrorFn)(
	int code, // SendFunds::PreSuccessTerminalCode
	NSString *_Nullable optl__errMsg,
	int optl__createTx_errCode, // monero_transfer_utils::CreateTransactionErrorCode
	uint64_t optl__spendable_balance,
	uint64_t optl__required_balance
);
typedef void (^SendFundsForm_SuccessFn)(
	uint64_t used_fee,
	uint64_t total_sent,
	size_t mixin,
	NSString *_Nullable optl__final_payment_id,
	NSString *_Nonnull signed_serialized_tx_string,
	NSString *_Nonnull tx_hash_string,
	NSString *_Nonnull tx_key_string,
	NSString *_Nonnull tx_pub_key_string,
	NSString *_Nonnull target_address,
	uint64_t final_total_wo_fee,
	BOOL isXMRAddressIntegrated,
	NSString *_Nullable optl__integratedAddressPIDForDisplay
);

@interface SendFundsFormSubmissionHandle : NSObject

- (id _Nonnull )init_canceled_fn:(void(^ _Nonnull)(void))canceled_fn
	authenticate_fn:(void(^ _Nonnull)(void))authenticate_fn
	willBeginSending_fn:(void(^_Nonnull)(void))willBeginSending_fn
	status_update_fn:(SendFundsForm_StatusUpdateFn _Nonnull)status_update_fn
	get_unspent_outs_fn:(SendFundsForm_RequestCallFn _Nonnull)get_unspent_outs_fn
	get_random_outs_fn:(SendFundsForm_RequestCallFn _Nonnull)get_random_outs_fn
	submit_raw_tx_fn:(SendFundsForm_RequestCallFn _Nonnull)submit_raw_tx_fn
	error_fn:(SendFundsForm_ErrorFn _Nonnull)error_fn
	success_fn:(SendFundsForm_SuccessFn _Nonnull)success_fn;

- (void)setupWith_fromWallet_didFailToInitialize:(BOOL)fromWallet_didFailToInitialize
fromWallet_didFailToBoot:(BOOL)fromWallet_didFailToBoot
fromWallet_needsImport:(BOOL)fromWallet_needsImport
requireAuthentication:(BOOL)requireAuthentication
sending_amount_double_NSString:(nullable NSString *)sending_amount_double_NSString
is_sweeping:(BOOL)is_sweeping
priority:(uint32_t)priority
hasPickedAContact:(BOOL)hasPickedAContact
optl__contact_payment_id:(nullable NSString *)optl__contact_payment_id
optl__contact_hasOpenAliasAddress:(BOOL)optl__contact_hasOpenAliasAddress
optl__cached_OAResolved_address:(nullable NSString *)optl__cached_OAResolved_address
optl__contact_address:(nullable NSString *)optl__contact_address
nettype:(NetType)objcNetType
from_address_string:(nonnull NSString *)from_address_string
sec_viewKey_string:(nonnull NSString *)sec_viewKey_string
sec_spendKey_string:(nonnull NSString *)sec_spendKey_string
pub_spendKey_string:(nonnull NSString *)pub_spendKey_string
optl__enteredAddressValue:(nullable NSString *)optl__enteredAddressValue
optl__resolvedAddress:(nullable NSString *)optl__resolvedAddress
resolvedAddress_fieldIsVisible:(BOOL)resolvedAddress_fieldIsVisible
optl__manuallyEnteredPaymentID:(nullable NSString *)optl__manuallyEnteredPaymentID
manuallyEnteredPaymentID_fieldIsVisible:(BOOL)manuallyEnteredPaymentID_fieldIsVisible
optl__resolvedPaymentID:(nullable NSString *)optl__resolvedPaymentID
resolvedPaymentID_fieldIsVisible:(BOOL)resolvedPaymentID_fieldIsVisible;

- (void)handle;
- (void)cb__authentication:(BOOL)did_pass;
- (void)cb_I__got_unspent_outs:(nullable NSString *)optl__err_msg args_string:(nullable NSString *)args_NSString;
- (void)cb_II__got_random_outs:(nullable NSString *)optl__err_msg args_string:(nullable NSString *)args_NSString;
- (void)cb_III__submitted_tx:(nullable NSString *)optl__err_msg;

@end
