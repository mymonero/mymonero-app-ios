//
//  monero_paymentID_utils.cpp
//  MyMonero
//
//  Created by Paul Shapiro on 12/1/17.
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

#include "monero_paymentID_utils.hpp"
#include "cryptonote_basic.h"
#include "cryptonote_basic/blobdatatype.h"
//
#include "string_tools.h"
using namespace epee;
//
//
//crypto::hash monero_paymentID_utils::new_long_plain_paymentID()
//{
//	return crypto::rand<crypto::hash>();
//}
//crypto::hash8 monero_paymentID_utils::new_short_plain_paymentID()
//{
//	return crypto::rand<crypto::hash8>();
//}
//
bool monero_paymentID_utils::parse_long_payment_id(const std::string& payment_id_str, crypto::hash& payment_id)
{
	cryptonote::blobdata payment_id_data;
	if (!epee::string_tools::parse_hexstr_to_binbuff(payment_id_str, payment_id_data)) {
		return false;
	}
	if (sizeof(crypto::hash) != payment_id_data.size()) {
		return false;
	}
	payment_id = *reinterpret_cast<const crypto::hash*>(payment_id_data.data());
	//
	return true;
}
bool monero_paymentID_utils::parse_short_payment_id(const std::string& payment_id_str, crypto::hash8& payment_id)
{
	cryptonote::blobdata payment_id_data;
	if (!epee::string_tools::parse_hexstr_to_binbuff(payment_id_str, payment_id_data)) {
		return false;
	}
	if (sizeof(crypto::hash8) != payment_id_data.size()) {
		return false;
	}
	payment_id = *reinterpret_cast<const crypto::hash8*>(payment_id_data.data());
	//
	return true;
}
bool monero_paymentID_utils::parse_payment_id(const std::string& payment_id_str, crypto::hash& payment_id)
{
	if (parse_long_payment_id(payment_id_str, payment_id)) {
		return true;
	}
	crypto::hash8 payment_id8;
	if (parse_short_payment_id(payment_id_str, payment_id8)) {
		memcpy(payment_id.data, payment_id8.data, 8);
		memset(payment_id.data + 8, 0, 24);
		return true;
	}
	return false;
}
