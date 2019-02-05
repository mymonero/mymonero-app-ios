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
#include "SendFundsFormSubmissionController.hpp"

typedef void (^SendFundsForm_StatusUpdateFn)(SendFunds::ProcessStep code);
typedef void (^SendFundsForm_RequestCallFn)(NSString *req_params_json_string);
typedef void (^SendFundsForm_ErrorFn)(
	SendFunds::PreSuccessTerminalCode code,
	NSString *optl__errMsg,
	monero_transfer_utils::CreateTransactionErrorCode optl__createTx_errCode,
	uint64_t optl__spendable_balance,
	uint64_t optl__required_balance
);
typedef void (^SendFundsForm_SuccessFn)(
	uint64_t used_fee,
	uint64_t total_sent,
	size_t mixin,
	NSString *optl__final_payment_id,
	NSString *signed_serialized_tx_string,
	NSString *tx_hash_string,
	NSString *tx_key_string,
	NSString *tx_pub_key_string,
	NSString *target_address,
	uint64_t final_total_wo_fee,
	BOOL isXMRAddressIntegrated,
	NSString *optl__integratedAddressPIDForDisplay
);

@interface SendFundsFormSubmissionHandle : NSObject

@end
