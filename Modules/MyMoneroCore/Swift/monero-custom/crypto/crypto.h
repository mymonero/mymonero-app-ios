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

#include <cstddef>
#include <iostream>
#include <boost/thread/mutex.hpp>
#include <boost/thread/lock_guard.hpp>
#include <boost/utility/value_init.hpp>
#include <boost/optional.hpp>
#include <type_traits>
#include <vector>

#include "pod-class.h"
//#include "common/util.h"
#include "memwipe.h"
#include "generic-ops.h"
#include "hex.h"
#include "span.h"
#include "hash.h"

namespace crypto {

//  extern "C" {
//#include "random.h"
//  }

  extern boost::mutex random_lock;

#pragma pack(push, 1)
  POD_CLASS ec_point {
    char data[32];
  };

  POD_CLASS ec_scalar {
    char data[32];
  };

  POD_CLASS public_key: ec_point {
    friend class crypto_ops;
  };

  using secret_key = tools::scrubbed<ec_scalar>;

  POD_CLASS public_keyV {
    std::vector<public_key> keys;
    int rows;
  };

  POD_CLASS secret_keyV {
    std::vector<secret_key> keys;
    int rows;
  };

  POD_CLASS public_keyM {
    int cols;
    int rows;
    std::vector<secret_keyV> column_vectors;
  };

  POD_CLASS key_derivation: ec_point {
    friend class crypto_ops;
  };

  POD_CLASS key_image: ec_point {
    friend class crypto_ops;
  };

  POD_CLASS signature {
    ec_scalar c, r;
    friend class crypto_ops;
  };
#pragma pack(pop)

  void hash_to_scalar(const void *data, size_t length, ec_scalar &res);

  static_assert(sizeof(ec_point) == 32 && sizeof(ec_scalar) == 32 &&
    sizeof(public_key) == 32 && sizeof(secret_key) == 32 &&
    sizeof(key_derivation) == 32 && sizeof(key_image) == 32 &&
    sizeof(signature) == 64, "Invalid structure size");

  class crypto_ops {
    crypto_ops();
    crypto_ops(const crypto_ops &);
    void operator=(const crypto_ops &);
    ~crypto_ops();

    static bool check_key(const public_key &);
    friend bool check_key(const public_key &);
  };

  /* Check a public key. Returns true if it is valid, false otherwise.
   */
  inline bool check_key(const public_key &key) {
    return crypto_ops::check_key(key);
  }


  const static crypto::public_key null_pkey = boost::value_initialized<crypto::public_key>();
}

CRYPTO_MAKE_HASHABLE(public_key)
