//
//  MyMoneroCore.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
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
import Foundation
import UIKit // because we use a WKWebView
//
// Principal type
final class MyMoneroCore : MyMoneroCoreJS
{
	// TODO? alternative to subclassing MyMoneroCoreJS would be to hold an instance of it and provide proxy fns as interface.
	//
	// Interface - Singleton
	static let shared = MyMoneroCore()
	//
	// Constants - Mixin
	static let _forkv7_minimumMixin: Int = 6
	static func _mixinToRingsize(_ mixin: Int) -> Int { return mixin + 1 }
	//
	static let thisFork_minMixin: Int = _forkv7_minimumMixin
	static var thisFork_minRingSize: Int {
		return _mixinToRingsize(thisFork_minMixin)
	}
	static var fixedMixin: Int = thisFork_minMixin // using the monero app default to remove MM user identifiers
	static var fixedRingsize: Int {
		return _mixinToRingsize(fixedMixin)
	}
	//
	// Lifecycle - Init
	private convenience init()
	{
		self.init(window: UIApplication.shared.delegate!.window!!)
	}
	override init(window: UIWindow)
	{
		super.init(window: window)
	}
}
