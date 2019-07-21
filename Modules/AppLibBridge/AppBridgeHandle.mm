//
//  AppBridgeHandle.mm
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

#include "AppBridgeHandle.h"
#include "serial_bridge_utils.hpp"
#include "AppBridge.hpp"
#include "Dispatch.ios.hpp"

using namespace std;
using namespace boost;
using namespace serial_bridge_utils;
using namespace App;

@interface AppBridgeHandle ()
{
	std::shared_ptr<App::Bridge> bridge_ptr;
	boost::signals2::connection evented_signal__connection;
}

@end

@implementation AppBridgeHandle
//
// Lifecycle - Init/deinit
- (id _Nonnull )init
{
	if (self = [super init]) {
		[self setup];
	}
	return self;
}
- (void)dealloc
{
	evented_signal__connection.disconnect();
	bridge_ptr = nullptr;
}
//
// Lifecycle - Setup
- (void)setup
{
	bridge_ptr = std::make_shared<App::Bridge>();
	//	std::weak_ptr<App::Bridge> weak_bridge_ptr = bridge_ptr;
	[self startObserving_bridge]; // do this before calling setup
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	bridge_ptr->setup(
		NULL, // not needed here .. used to, e.g., hold onto a global asio context used by, e.g., Dispatch_…
		std::make_shared<string>(string(((NSString *)paths[0]).UTF8String)),
		MAINNET,
		std::make_shared<Dispatch::Dispatch_ios>()
	);
	//
	// TODO: delete…… kept as an example
//	__weak AppBridgeHandle *refToSelf = self;
//	(*bridge_ptr).set__get_unspent_outs_fn([refToSelf] (LightwalletAPI_Req_GetUnspentOuts req_params) -> void
//	{
//		refToSelf.get_unspent_outs_fn([NSString stringWithUTF8String:monero_send_routine::json_string_from_req_GetUnspentOuts(req_params).c_str()]);
//	});
}
- (void)startObserving_bridge
{
	__weak AppBridgeHandle *refToSelf = self;
	evented_signal__connection = bridge_ptr->evented_signal.connect([refToSelf] (string msg) {
		[refToSelf event_occurred:[NSString stringWithUTF8String:msg.c_str()]];
	});
}
//
// Imperatives

// TODO: delete..... just an example
- (void)exec:(NSString *)moduleName cmdName:(NSString *)cmdName params_fn:(std::function<void(Value &params, Document::AllocatorType &a)>)params_fn
{
	auto rep_msg = Bridge_exec::new_msg_with(
		string(moduleName.UTF8String),
		string(cmdName.UTF8String),
		params_fn
	);
	(*bridge_ptr).exec(rep_msg);
}

	
- (void)event_occurred:(NSString *)msg
{
	using namespace Bridge_event;
	//
	NSLog(@"event occurred... TODO: route %@", msg);
	//
	_Convenience__Event ev = new_convenience__event_with(string(msg.UTF8String));
	if (ev.eventName == Name__getUserToEnterExistingPassword) {
	} else {
		BOOST_ASSERT_MSG(false, "Unrecognized event name");
	}
}

	
	
	
@end

