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

#include <unistd.h>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <boost/thread/mutex.hpp>
#include <boost/thread/lock_guard.hpp>
#include <boost/shared_ptr.hpp>

//#include "common/varint.h"
#include "warnings.h"
#include "crypto.h"
#include "hash.h"

namespace crypto {

  using std::abort;
  using std::int32_t;
  using std::int64_t;
  using std::size_t;
  using std::uint32_t;
  using std::uint64_t;

  extern "C" {
#include "crypto-ops.h"
//#include "random.h"
  }

  boost::mutex random_lock;

  static inline unsigned char *operator &(ec_point &point) {
    return &reinterpret_cast<unsigned char &>(point);
  }

  static inline const unsigned char *operator &(const ec_point &point) {
    return &reinterpret_cast<const unsigned char &>(point);
  }

  static inline unsigned char *operator &(ec_scalar &scalar) {
    return &reinterpret_cast<unsigned char &>(scalar);
  }

  static inline const unsigned char *operator &(const ec_scalar &scalar) {
    return &reinterpret_cast<const unsigned char &>(scalar);
  }

  /* generate a random 32-byte (256-bit) integer and copy it to res */
//  static inline void random_scalar_not_thread_safe(ec_scalar &res) {
//    unsigned char tmp[64];
//    generate_random_bytes_not_thread_safe(64, tmp);
//    sc_reduce(tmp);
//    memcpy(&res, tmp, 32);
//  }
//  static inline void random_scalar(ec_scalar &res) {
//    boost::lock_guard<boost::mutex> lock(random_lock);
//    random_scalar_not_thread_safe(res);
//  }

//  void hash_to_scalar(const void *data, size_t length, ec_scalar &res) {
//    cn_fast_hash(data, length, reinterpret_cast<hash &>(res));
//    sc_reduce32(&res);
//  }


  bool crypto_ops::check_key(const public_key &key) {
    ge_p3 point;
    return ge_frombytes_vartime(&point, &key) == 0;
  }


//  static void hash_to_ec(const public_key &key, ge_p3 &res) {
//    hash h;
//    ge_p2 point;
//    ge_p1p1 point2;
//    cn_fast_hash(std::addressof(key), sizeof(public_key), h);
//    ge_fromfe_frombytes_vartime(&point, reinterpret_cast<const unsigned char *>(&h));
//    ge_mul8(&point2, &point);
//    ge_p1p1_to_p3(&res, &point2);
//  }


}
