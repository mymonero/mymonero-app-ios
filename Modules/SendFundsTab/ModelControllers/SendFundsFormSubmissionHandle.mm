//
//  SendFundsFormSubmissionHandle.mm
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

#import "SendFundsFormSubmissionHandle.h"
#include "SendFundsFormSubmissionController.hpp"
#include "serial_bridge_utils.hpp"
#include "cryptonote_basic_impl.h"
#include "MyMoneroCore_ObjCpp.h"

using namespace std;
using namespace boost;
using namespace serial_bridge_utils;
using namespace monero_transfer_utils;
using namespace monero_send_routine;

@interface SendFundsFormSubmissionHandle ()
{
	SendFunds::FormSubmissionController *controller_ptr;
}
@property (nonatomic, copy) void (^canceled_fn)(void);
@property (nonatomic, copy) void (^authenticate_fn)(void);
@property (nonatomic, copy) SendFundsForm_StatusUpdateFn status_update_fn;
@property (nonatomic, copy) void (^willBeginSending_fn)(void);
@property (nonatomic, copy) SendFundsForm_RequestCallFn get_unspent_outs_fn;
@property (nonatomic, copy) SendFundsForm_RequestCallFn get_random_outs_fn;
@property (nonatomic, copy) SendFundsForm_RequestCallFn submit_raw_tx_fn;
@property (nonatomic, copy) SendFundsForm_ErrorFn error_fn;
@property (nonatomic, copy) SendFundsForm_SuccessFn success_fn;

@end

@implementation SendFundsFormSubmissionHandle
//
// Lifecycle - Init/deinit
- (id _Nonnull )init_canceled_fn:(void(^ _Nonnull)(void))canceled_fn
				 authenticate_fn:(void(^ _Nonnull)(void))authenticate_fn
			 willBeginSending_fn:(void(^_Nonnull)(void))willBeginSending_fn
				status_update_fn:(SendFundsForm_StatusUpdateFn _Nonnull)status_update_fn
			 get_unspent_outs_fn:(SendFundsForm_RequestCallFn _Nonnull)get_unspent_outs_fn
			  get_random_outs_fn:(SendFundsForm_RequestCallFn _Nonnull)get_random_outs_fn
				submit_raw_tx_fn:(SendFundsForm_RequestCallFn _Nonnull)submit_raw_tx_fn
						error_fn:(SendFundsForm_ErrorFn _Nonnull)error_fn
					  success_fn:(SendFundsForm_SuccessFn _Nonnull)success_fn
{
	if (self = [super init]) {
		controller_ptr = NULL; // safety init
		//
		self.canceled_fn = canceled_fn;
		self.authenticate_fn = authenticate_fn;
		self.willBeginSending_fn = willBeginSending_fn;
		self.get_unspent_outs_fn = get_unspent_outs_fn;
		self.get_random_outs_fn = get_random_outs_fn;
		self.submit_raw_tx_fn = submit_raw_tx_fn;
		self.status_update_fn = status_update_fn;
		self.error_fn = error_fn;
		self.success_fn = success_fn;
		//
		// wait for "setup…"
	}
	return self;
}
- (void)dealloc
{
	if (controller_ptr != NULL) {
		delete controller_ptr;
		controller_ptr = NULL;
	}
}
//
// Lifecycle - Setup
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
				resolvedPaymentID_fieldIsVisible:(BOOL)resolvedPaymentID_fieldIsVisible
{
	optional<string> sending_amount_double_string = none;
	if (sending_amount_double_NSString != nil && sending_amount_double_NSString.length > 0) {
		sending_amount_double_string = string(sending_amount_double_NSString.UTF8String);
	}
	optional<string> contact_payment_id = none;
	if (optl__contact_payment_id != nil) {
		contact_payment_id = string(optl__contact_payment_id.UTF8String);
	}
	optional<bool> contact_hasOpenAliasAddress = none;
	if (hasPickedAContact) { // this is the only indication we have as to whether the value should be used
		contact_hasOpenAliasAddress = optl__contact_hasOpenAliasAddress;
	}
	optional<string> cached_OAResolved_address = none;
	if (optl__cached_OAResolved_address != nil) {
		cached_OAResolved_address = string(optl__cached_OAResolved_address.UTF8String);
	}
	optional<string> contact_address = none;
	if (optl__contact_address != nil) {
		contact_address = string(optl__contact_address.UTF8String);
	}
	optional<string> enteredAddressValue = none;
	if (optl__enteredAddressValue != nil) {
		enteredAddressValue = string(optl__enteredAddressValue.UTF8String);
	}
	optional<string> resolvedAddress = none;
	if (optl__resolvedAddress != nil) {
		resolvedAddress = string(optl__resolvedAddress.UTF8String);
	}
	optional<string> resolvedPaymentID = none;
	if (optl__resolvedPaymentID != nil) {
		resolvedPaymentID = string(optl__resolvedPaymentID.UTF8String);
	}
	optional<string> manuallyEnteredPaymentID = none;
	if (optl__manuallyEnteredPaymentID != nil) {
		manuallyEnteredPaymentID = string(optl__manuallyEnteredPaymentID.UTF8String);
	}
	SendFunds::Parameters parameters{
		fromWallet_didFailToInitialize ? true : false,
		fromWallet_didFailToBoot ? true : false,
		fromWallet_needsImport ? true : false,
		//
		requireAuthentication ? true : false,
		//
		sending_amount_double_string,
		is_sweeping ? true : false,
		priority,
		//
		hasPickedAContact ? true : false,
		contact_payment_id,
		contact_hasOpenAliasAddress,
		cached_OAResolved_address,
		contact_address,
		//
		(cryptonote::network_type)nettype_from_objcType(objcNetType),
		string(from_address_string.UTF8String),
		string(sec_viewKey_string.UTF8String),
		string(sec_spendKey_string.UTF8String),
		string(pub_spendKey_string.UTF8String),
		//
		enteredAddressValue,
		//
		resolvedAddress,
		resolvedAddress_fieldIsVisible ? true : false,
		//
		manuallyEnteredPaymentID,
		manuallyEnteredPaymentID_fieldIsVisible ? true : false,
		//
		resolvedPaymentID,
		resolvedPaymentID_fieldIsVisible ? true : false,
		//
		[self] (SendFunds::ProcessStep step)
		{ // preSuccess_nonTerminal_validationMessageUpdate_fn
			self.status_update_fn(step);
		},
		[self] ( // failure_fn
			SendFunds::PreSuccessTerminalCode code,
			optional<string> msg,
			optional<monero_transfer_utils::CreateTransactionErrorCode> createTx_errCode,
			optional<uint64_t> spendable_balance,
			optional<uint64_t> required_balance
		) -> void {
			self.error_fn(
				code,
				msg != none ? [NSString stringWithUTF8String:(*msg).c_str()] : nil,
				createTx_errCode ? *createTx_errCode : monero_transfer_utils::CreateTransactionErrorCode::noError,
				spendable_balance ? *spendable_balance : 0,
				required_balance ? *required_balance : 0
			);
		},
		[self] () -> void { // preSuccess_passedValidation_willBeginSending
			self.willBeginSending_fn();
		},
		//
		[self] () -> void { // canceled_fn
			self.canceled_fn();
		},
		[self] (SendFunds::Success_RetVals retVals) -> void
		{ // success_fn
			self.success_fn(
				retVals.used_fee,
				retVals.total_sent,
				retVals.mixin,
				retVals.final_payment_id ? [NSString stringWithUTF8String:retVals.final_payment_id.get().c_str()] : nil,
				[NSString stringWithUTF8String:retVals.signed_serialized_tx_string.c_str()],
				[NSString stringWithUTF8String:retVals.tx_hash_string.c_str()],
				[NSString stringWithUTF8String:retVals.tx_key_string.c_str()],
				[NSString stringWithUTF8String:retVals.tx_pub_key_string.c_str()],
				[NSString stringWithUTF8String:retVals.target_address.c_str()],
				retVals.final_total_wo_fee,
				retVals.isXMRAddressIntegrated,
				retVals.integratedAddressPIDForDisplay ? [NSString stringWithUTF8String:retVals.integratedAddressPIDForDisplay.get().c_str()] : nil
			);
		}
	};
	controller_ptr = new SendFunds::FormSubmissionController{parameters}; // heap alloc
	if (!controller_ptr) { // exception will be thrown if oom but JIC, since null ptrs are somehow legal in WASM
		self.error_fn(SendFunds::PreSuccessTerminalCode::msgProvided, @"Out of memory (form submission controller)", monero_transfer_utils::CreateTransactionErrorCode::noError, 0, 0);
		return;
	}
	(*controller_ptr).set__authenticate_fn([self] () -> void
	{ // authenticate_fn - this is not guaranteed to be called but it will be if requireAuthentication is true
		self.authenticate_fn();
	});
	(*controller_ptr).set__get_unspent_outs_fn([self] (LightwalletAPI_Req_GetUnspentOuts req_params) -> void
	{
		self.get_unspent_outs_fn([NSString stringWithUTF8String:monero_send_routine::json_string_from_req_GetUnspentOuts(req_params).c_str()]);
	});
	(*controller_ptr).set__get_random_outs_fn([self] (LightwalletAPI_Req_GetRandomOuts req_params) -> void
	{
		self.get_random_outs_fn([NSString stringWithUTF8String:monero_send_routine::json_string_from_req_GetRandomOuts(req_params).c_str()]);
	});
	(*controller_ptr).set__submit_raw_tx_fn([self] (LightwalletAPI_Req_SubmitRawTx req_params) -> void
	{
		self.submit_raw_tx_fn([NSString stringWithUTF8String:monero_send_routine::json_string_from_req_SubmitRawTx(req_params).c_str()]);
	});
}
//
// Imperatives
- (void)handle
{
	(*controller_ptr).handle();
}
- (void)cb__authentication:(BOOL)did_pass
{
	NSAssert(controller_ptr != NULL, @"Expected non-NULL controller_ptr");
	(*controller_ptr).cb__authentication(did_pass);
}
- (void)cb_I__got_unspent_outs:(nullable NSString *)optl__err_msg args_string:(nullable NSString *)args_NSString
{
	NSAssert(controller_ptr != NULL, @"Expected non-NULL controller_ptr");
	boost::optional<string> err_msg__optional = boost::none;
	if (optl__err_msg != NULL || optl__err_msg.length != 0) {
		err_msg__optional = std::string(optl__err_msg.UTF8String);
		(*controller_ptr).cb_I__got_unspent_outs(err_msg__optional, boost::none);
		// ^- alternatively, we could call self.error_fn, but we may as well make use of the SendFunds controller
		return;
	}
	boost::property_tree::ptree json_root;
	std::string args_string = std::string(args_NSString.UTF8String);
	if (!parsed_json_root(args_string, json_root)) {
		self.error_fn(SendFunds::PreSuccessTerminalCode::msgProvided, @"Invalid JSON", monero_transfer_utils::CreateTransactionErrorCode::noError, 0, 0);
		return;
	}
	(*controller_ptr).cb_I__got_unspent_outs(err_msg__optional, json_root);
}
- (void)cb_II__got_random_outs:(nullable NSString *)optl__err_msg args_string:(nullable NSString *)args_NSString
{
	NSAssert(controller_ptr != NULL, @"Expected non-NULL controller_ptr");
	boost::optional<string> err_msg__optional = boost::none;
	if (optl__err_msg != NULL || optl__err_msg.length != 0) {
		err_msg__optional = std::string(optl__err_msg.UTF8String);
		(*controller_ptr).cb_II__got_random_outs(err_msg__optional, boost::none);
		// ^- alternatively, we could call self.error_fn, but we may as well make use of the SendFunds controller
		return;
	}
	boost::property_tree::ptree json_root;
	std::string args_string = std::string(args_NSString.UTF8String);
	if (!parsed_json_root(args_string, json_root)) {
		self.error_fn(SendFunds::PreSuccessTerminalCode::msgProvided, @"Invalid JSON", monero_transfer_utils::CreateTransactionErrorCode::noError, 0, 0);
		return;
	}
	(*controller_ptr).cb_II__got_random_outs(err_msg__optional, json_root);
}
- (void)cb_III__submitted_tx:(nullable NSString *)optl__err_msg
{
	boost::optional<string> err_msg__optional = boost::none;
	if (optl__err_msg != NULL || optl__err_msg.length != 0) {
		err_msg__optional = std::string(optl__err_msg.UTF8String);
	}
	NSAssert(controller_ptr != NULL, @"Expected non-NULL controller_ptr");
	(*controller_ptr).cb_III__submitted_tx(err_msg__optional);
}

@end
