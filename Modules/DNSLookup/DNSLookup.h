//
//  DNSLookup.h
//  MyMonero
//
//  Created by Paul Shapiro on 8/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
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
