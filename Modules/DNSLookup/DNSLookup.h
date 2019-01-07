//
//  DNSLookup.h
//  MyMonero
//
//  Created by Paul Shapiro on 8/29/17.
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
#import <Foundation/Foundation.h>
#include "dns_sd.h" // in public .h for error codes
//
// Shared/pre-emptive declarations
@protocol DNSLookupEventDelegate;
enum DNSLookup_DNSSECStatus: NSInteger
{
	DNSLookup_DNSSECStatus_undetermined		= 0, // zero value
	//
	DNSLookup_DNSSECStatus_secure			= 1,
	DNSLookup_DNSSECStatus_insecure			= 2,
	DNSLookup_DNSSECStatus_indeterminate	= 3,
	DNSLookup_DNSSECStatus_bogus			= 4,
	//
	DNSLookup_DNSSECStatus_unrecognized		= -1
};
extern NSString *_Nullable NSStringFromDNSSECStatus(enum DNSLookup_DNSSECStatus value);
//
// Principal object - Interface
@interface DNSLookup: NSObject
//
// Lifecycle
- (instancetype _Nonnull)initWithAddress:(NSString * _Nonnull)address_fullname // designated initializer
					isValidationOptional:(BOOL)isValidationOptional;
//
// Readable after init
@property (nonatomic, copy, readonly, nonnull) NSString *address_fullname;
@property (nonatomic, readonly) BOOL isValidationOptional;
//
// Settable after init
@property (nonatomic, weak, nullable) id<DNSLookupEventDelegate> delegate;
//
// Runtime
- (/*didStart: */BOOL)start; // call after `-init…`
//
// Final state -- Access these only around delegate's -dnssdServiceDidStop:
@property (nonatomic, strong, readonly, nonnull) NSMutableArray *recordsStrings;
@property (nonatomic, readonly) enum DNSLookup_DNSSECStatus dnssecStatus;
// -or-
@property (nonatomic, strong, readonly, nullable) NSError *error;
//
//
@end
//
// Protocols
@protocol DNSLookupEventDelegate <NSObject>
//
// These methods are called on the main thread.
@optional
- (void)dnssdServiceWillResolve:(DNSLookup * _Nonnull)service; // called as the service starts resolving.

- (void)dnssdServiceFailedToResolveWithError:(DNSLookup * _Nonnull)service; // Called when the service fails to resolve.  The resolve will be stopped immediately after this delegate method returns. Check instance property `error`.

- (void)dnssdServiceDidStop:(DNSLookup * _Nonnull)service; // Called when a resolve stops (except if you call -stop on it).

@end
