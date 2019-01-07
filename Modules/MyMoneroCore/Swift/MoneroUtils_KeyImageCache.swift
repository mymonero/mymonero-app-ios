//
//  MoneroUtils_KeyImageCache.swift
//  MyMonero
//
//  Created by Paul Shapiro on 1/2/18.
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

import Foundation

extension MoneroUtils
{
	class KeyImageCache // instantiate and store on a wallet object rather than as singleton, for security
	{
		typealias _KeyImageCacheKey = String // NOT the key image :)
		typealias _KeyImageCacheKeyTuple = (
			tx_pub_key: MoneroTransactionPubKey,
			public_address: MoneroAddress,
			out_index: UInt64
		)
		static func _new_cacheKey(
			from cacheKeyTuple: _KeyImageCacheKeyTuple
		) -> _KeyImageCacheKey {
			return "\(cacheKeyTuple.tx_pub_key):\(cacheKeyTuple.public_address):\(cacheKeyTuple.out_index)"
		}
		//
		// Properties
		fileprivate var keyImages_byCacheKey = [_KeyImageCacheKey: MoneroKeyImage]()
		//
		// Instance - Interface - Accessors
		func lazy_keyImage(
			tx_pub_key: MoneroTransactionPubKey,
			out_index: UInt64,
			public_address: MoneroAddress,
			sec_keys: MoneroKeyDuo,
			pub_spendKey: MoneroKey
		) -> MoneroKeyImage {
			let cacheKeyTuple = (tx_pub_key, public_address, out_index)
			let cacheKey = KeyImageCache._new_cacheKey(from: cacheKeyTuple)
			var cached_keyImage = self.keyImages_byCacheKey[cacheKey]
			if cached_keyImage == nil { //
				cached_keyImage = MyMoneroCore.shared_objCppBridge.new__key_image_from( // momentarily incorrect name
					tx_pub_key: tx_pub_key,
					out_index: out_index,
					public_address: public_address,
					sec_keys: sec_keys,
					pub_spendKey: pub_spendKey
				)
				self.keyImages_byCacheKey[cacheKey] = cached_keyImage // now it's correct
			}
			return cached_keyImage!
		}
	}
}



