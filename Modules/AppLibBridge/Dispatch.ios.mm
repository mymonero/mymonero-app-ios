//
//  Dispatch.ios.cpp
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

#include "Dispatch.ios.hpp"
using namespace Dispatch;
//
//
// Dispatch::CancelableTimerHandle_ios
//
CancelableTimerHandle_ios::~CancelableTimerHandle_ios() {
	if (_t) {
		[_t release];
		_t = NULL;
	}
}
//
void CancelableTimerHandle_ios::cancel() {
	if (_t) {
		isCanceled = true;
		[_t invalidate];
	}
}
//
//
// Dispatch::Dispatch_ios
//
std::unique_ptr<CancelableTimerHandle> Dispatch_ios::after(uint32_t ms, std::function<void()>&& fn)
{
	NSDate *d = [NSDate dateWithTimeIntervalSinceNow:ms / 1000.0f];
	NSTimer *t = [[NSTimer alloc] initWithFireDate:d interval:0 repeats:NO block:^(NSTimer * _Nonnull timer) {
		fn();
	}];
	return std::make_unique<CancelableTimerHandle_ios>(t);
}
void Dispatch_ios::async(std::function<void()>&& fn)
{
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			(int64_t)(0 * NSEC_PER_SEC)),
			dispatch_get_main_queue(),
			[fn = std::move(fn)]() { // lol apparently we can pass C++ lambdas in place of blocks … which is useful since we want the C++14 lambda move-capture semantics for the proper lifetime management of the 'fn' being passed in... awesome! (hopefully this isn't subject to any weird safety caveats)
				fn();
			}
	);
}
