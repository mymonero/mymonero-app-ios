// Copyright (c) 2014-2018, The Monero Project
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Parts of this file are originally copyright (c) 2012-2013 The Cryptonote developers

#pragma once
#include "blobdatatype.h"
#include "cryptonote_basic_impl.h"
//#include "account.h"
//#include "subaddress_index.h"
//#include "include_base_utils.h"
#include "crypto.h"
#include "hash.h"
#include <unordered_map>

namespace epee
{
  class wipeable_string;
}

namespace cryptonote
{
	void get_blob_hash(const blobdata& blob, crypto::hash& res);
	crypto::hash get_blob_hash(const blobdata& blob);
	std::string short_hash_str(const crypto::hash& h);

	
	//---------------------------------------------------------------
	template<class t_object>
	bool t_serializable_object_to_blob(const t_object& to, blobdata& b_blob)
	{
		std::stringstream ss;
		binary_archive<true> ba(ss);
		bool r = ::serialization::serialize(ba, const_cast<t_object&>(to));
		b_blob = ss.str();
		return r;
	}
	//---------------------------------------------------------------
	template<class t_object>
	blobdata t_serializable_object_to_blob(const t_object& to)
	{
		blobdata b;
		t_serializable_object_to_blob(to, b);
		return b;
	}
	//---------------------------------------------------------------
	template<class t_object>
	bool get_object_hash(const t_object& o, crypto::hash& res)
	{
		get_blob_hash(t_serializable_object_to_blob(o), res);
		return true;
	}
	//---------------------------------------------------------------
	template<class t_object>
	size_t get_object_blobsize(const t_object& o)
	{
		blobdata b = t_serializable_object_to_blob(o);
		return b.size();
	}
	//---------------------------------------------------------------
	template<class t_object>
	bool get_object_hash(const t_object& o, crypto::hash& res, size_t& blob_size)
	{
		blobdata bl = t_serializable_object_to_blob(o);
		blob_size = bl.size();
		get_blob_hash(bl, res);
		return true;
	}
	//---------------------------------------------------------------
	template <typename T>
	std::string obj_to_json_str(T& obj)
	{
		std::stringstream ss;
		json_archive<true> ar(ss, true);
		bool r = ::serialization::serialize(ar, obj);
		CHECK_AND_ASSERT_MES(r, "", "obj_to_json_str failed: serialization::serialize returned false");
		return ss.str();
	}

}
