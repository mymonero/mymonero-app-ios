//
//  DNSLookup.m
//  MyMonero
//
//  Created by Paul Shapiro on 8/29/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//
//
#import "DNSLookup.h"
// TODO: clean this up / strip unnecessary
#include <ctype.h>
//#include <stdio.h>          // For stdout, stderr
//#include <stdlib.h>         // For exit()
#include <string.h>         // For strlen(), strcpy()
#include <errno.h>          // For errno, EINTR
#include <time.h>
#include <sys/types.h>      // For u_char
#include <unistd.h>         // For getopt() and optind
#include <netdb.h>          // For getaddrinfo()
#include <sys/time.h>       // For struct timeval
#include <sys/socket.h>     // For AF_INET
#include <netinet/in.h>     // For struct sockaddr_in()
#include <arpa/inet.h>      // For inet_addr()
#include <net/if.h>         // For if_nametoindex()
//
#define RR_TYPE_SIZE 16
//
#ifdef DEBUG
// TODO: check if these are defined! this will probably conflict with any other C/ObjC DDLogInfo/Warn/Error
#define DDLogInfo(s, ...) NSLog(@"%@  %@", @"💬",  [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define DDLogWarn(s, ...) NSLog(@"%@  %@", @"⚠️",  [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define DDLogError(s, ...) NSLog(@"%@  %@", @"❌",  [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define DDLogInfo(s, ...)
#define DDLogWarn(s, ...)
#define DDLogError(s, ...)
#endif
//
//
@interface DNSLookup ()
{
	// ivars - Runtime
	DNSServiceRef _dnsServiceRef;
	BOOL _hasTornDown;
}
//
// Properties - Initial
@property (nonatomic, copy, readwrite, nonnull) NSString *address_fullname;
@property (nonatomic, readwrite) BOOL isValidationOptional;
//
// Properties - Runtime
@property (nonatomic, strong, readwrite) NSTimer *resolveTimeoutTimer;
//
// Properties - Final state
@property (nonatomic, strong, readwrite, nonnull) NSMutableArray *recordsStrings;
@property (nonatomic, readwrite) enum DNSLookup_DNSSECStatus dnssecStatus;
// -or-
@property (nonatomic, strong, readwrite, nullable) NSError *error;
//
@end
//
//
@implementation DNSLookup
//
// Lifecycle - Init
- (instancetype _Nonnull)initWithAddress:(NSString *)address_fullname
					isValidationOptional:(BOOL)isValidationOptional
{
	self = [super init];
	{
		self.address_fullname = address_fullname;
		self.isValidationOptional = isValidationOptional;
	}
	{
		self.recordsStrings = [NSMutableArray new];
	}
	//
	return self;
}
//
// Lifecycle - Teardown & Stopping/Cancelling
- (void)dealloc
{
	DDLogInfo(@"Tearing down a DNSLookup instance.");
	_hasTornDown = YES;
	self.delegate = nil; // just to be explicit
	[self cancel]; // if necessary
}
- (void)cancel
{
	if (_dnsServiceRef == NULL) {
		return; // ignoring - may be getting called redundantly on -dealloc
	}
	[self stopWithError:nil notify:NO];
}
- (void)stopWithError:(NSError *)error notify:(BOOL)notify
{ // "An internal bottleneck for shutting down the object."
	if (_dnsServiceRef == NULL) {
		assert(false);
		DDLogWarn(@"DNSLookup: Already exited. Ignoring.");
		return; // ignoring
	}
	if (_hasTornDown) {
		DDLogWarn(@"DNSLookup: Already torn down. Ignoring.");
		return; // ignoring
	}
	if (notify) {
		if (error != nil) {
			self.error = error;
			if (self.delegate != nil) { // might have been nulled on teardown
				if ([self.delegate respondsToSelector:@selector(dnssdServiceFailedToResolveWithError:)]) {
					[self.delegate dnssdServiceFailedToResolveWithError:self];
				}
			}
		}
	}
	if (_dnsServiceRef != NULL) {
		DNSServiceRefDeallocate(_dnsServiceRef);
		_dnsServiceRef = NULL;
	}
	{
		[self.resolveTimeoutTimer invalidate];
		self.resolveTimeoutTimer = nil;
	}
	if (notify) {
		if (self.delegate != nil) { // might have been nulled on teardown
			if ([self.delegate respondsToSelector:@selector(dnssdServiceDidStop:)]) {
				[self.delegate dnssdServiceDidStop:self];
			}
		}
	}
}
- (void)stopAndNotifyWith_netServicesErrorCode:(DNSServiceErrorType)errorCode
{
	NSError *error = nil;
	if (errorCode != kDNSServiceErr_NoError) {
		error = [NSError errorWithDomain:NSNetServicesErrorDomain
									code:errorCode
								userInfo:nil];
	}
	[self stopWithError:error notify:YES];
}
//
// Runtime - Imperatives
- (BOOL)start
{
	if (_dnsServiceRef != NULL) {
		NSAssert(false, @"-start called after already started");
		return NO;
	}
	DNSServiceFlags flags = 0;
	{
		flags |= (DNSServiceFlags)kDNSServiceFlagsReturnIntermediates; // for errors
		flags |= (DNSServiceFlags)kDNSServiceFlagsTimeout; // want for txt lookup?
		flags |= (DNSServiceFlags)kDNSServiceFlagsLongLivedQuery; // b/c it's a TXT record lookup
//		flags |= (DNSServiceFlags)kDNSServiceFlagsUnicastResponse; // TODO: ?
//		flags |= (DNSServiceFlags)kDNSServiceFlagsSuppressUnusable; // TODO: do we want this?
//
//		flags |= (DNSServiceFlags)kDNSServiceFlagsValidateOptional; // TODO: unless they flip the flag to true via settings - "OpenAlias: Require DNSSEC OK"
		// - OR -
		flags |= (DNSServiceFlags)kDNSServiceFlagsValidate;
	}
	//
	DNSServiceRef dnsServiceRef = NULL; // TODO: change to instance prop
	DNSServiceErrorType errorCode = DNSServiceQueryRecord(
		&dnsServiceRef,
		flags,
		kDNSServiceInterfaceIndexAny,
		[self.address_fullname cStringUsingEncoding:NSUTF8StringEncoding],
		kDNSServiceType_TXT,
		kDNSServiceClass_IN,
		qr_reply,
		(__bridge void *)(self)
	);
	self->_dnsServiceRef = dnsServiceRef;
	if (errorCode != kDNSServiceErr_NoError) {
		[self stopAndNotifyWith_netServicesErrorCode:errorCode];
		return NO;
	}
	//
	errorCode = DNSServiceSetDispatchQueue(dnsServiceRef, dispatch_get_main_queue());
	if (errorCode != kDNSServiceErr_NoError) {
		[self stopAndNotifyWith_netServicesErrorCode:errorCode];
		return NO;
	}
	{
		self.resolveTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
																	target:self
																  selector:@selector(didFireResolveTimeoutTimer:)
																  userInfo:nil
																   repeats:NO];
		// "Service resolution /never/ times out. This is convenient in some circumstances, but it's generally best to use some reasonable timeout.  Here we use an NSTimer to trigger a failure if we spend more than 30 seconds waiting for the resolve."
		//
		if ([self.delegate respondsToSelector:@selector(dnssdServiceWillResolve:)]) {
			[self.delegate dnssdServiceWillResolve:self];
		}
	}
	return YES;
}
//
// Delegation - Internal - Lookup events
- (void)didChangeTo_hasNoMoreComing // terminal
{ // must dealloc service and yield
	[self stopWithError:nil notify:YES];
}
- (void)obtainedReplyWith_recordText:(NSString *)raw_recordText
{ // callable multiple times
	assert(raw_recordText != nil);
	// must strip prefixing garbage char - or use dns_util.h to parse the DNS record - but that did not work on first try
	NSString *recordText = [raw_recordText substringFromIndex:1];
	[self.recordsStrings addObject:recordText];
}
- (void)obtainedReplyWith_DNSSECStatus:(enum DNSLookup_DNSSECStatus)dnssecStatus
{ // only expecting one call
	self.dnssecStatus = dnssecStatus;
}
//
// Delegation - Internal - Timer
- (void)didFireResolveTimeoutTimer:(NSTimer *)timer
{
	assert(timer == self.resolveTimeoutTimer);
	[self stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:kDNSServiceErr_Timeout userInfo:nil] notify:YES];
}
//
// Delegation - DNSSD - C
static void DNSSD_API qr_reply(
							   DNSServiceRef sdref,
							   const DNSServiceFlags flags,
							   uint32_t ifIndex,
							   DNSServiceErrorType errorCode,
							   const char *fullname,
							   uint16_t rrtype,
							   uint16_t rrclass,
							   uint16_t rdlen,
							   const void *rdata,
							   uint32_t ttl,
							   void *context
							   )
{
	assert([NSThread isMainThread]); // because dnsServiceRef dispatches to the main queue
	assert(rrtype == kDNSServiceType_TXT);
	//
	DNSLookup *lookup = (__bridge DNSLookup *)context;
	assert([lookup isKindOfClass:[DNSLookup class]]);
	assert(sdref == lookup->_dnsServiceRef); // TODO: this won't compile…
	//
	if (lookup->_hasTornDown) {
		DDLogWarn(@"DNSLookup/qr_reply: Already torn down. Ignoring.");
		return; // ignoring
	}
	//
	if (errorCode != kDNSServiceErr_NoError) {
		DDLogError(@"Lookup error: %d", errorCode);
		[lookup stopAndNotifyWith_netServicesErrorCode:errorCode];
		return;
	}
	//
	BOOL op_isAdd = (flags & kDNSServiceFlagsAdd) != 0;
	if (op_isAdd == false) {
		DDLogWarn(@"Remove (non-add) operation received. Ignoring.");
		return; // we should be able to ignore this
	}
	//
	BOOL isAValidateFlagSet = (flags & (kDNSServiceFlagsValidate | kDNSServiceFlagsValidateOptional)) != 0;
	if (isAValidateFlagSet == false) {
		assert(rdata != NULL);
		NSData *rData = [NSMutableData dataWithBytes:rdata length:rdlen];
		NSString *recordString = [[NSString alloc] initWithData:rData encoding:NSASCIIStringEncoding];
		//
		[lookup obtainedReplyWith_recordText:recordString];
	} else {
		DNSServiceFlags dnssecStatusCheckable_flags = flags;
		{ // must first clear all o/p bits, and then check for dnssec status
			dnssecStatusCheckable_flags &= ~kDNSServiceOutputFlags;
			NSCAssert(dnssecStatusCheckable_flags != 0, @"check_flags ought to have DNSSEC status set on it");
		}
		enum DNSLookup_DNSSECStatus dnssecStatus;
		if (dnssecStatusCheckable_flags & kDNSServiceFlagsSecure) {
			dnssecStatus = DNSLookup_DNSSECStatus_secure;
		} else if (dnssecStatusCheckable_flags & kDNSServiceFlagsInsecure) {
			dnssecStatus = DNSLookup_DNSSECStatus_insecure;
		} else if (dnssecStatusCheckable_flags & kDNSServiceFlagsIndeterminate) {
			dnssecStatus = DNSLookup_DNSSECStatus_indeterminate;
		} else if (dnssecStatusCheckable_flags & kDNSServiceFlagsBogus) {
			dnssecStatus = DNSLookup_DNSSECStatus_bogus;
		} else {
			DDLogError(@"Unrecognized DNSSEC status flag… ");
			dnssecStatus = DNSLookup_DNSSECStatus_unrecognized;
			assert(false);
		}
		[lookup obtainedReplyWith_DNSSECStatus:dnssecStatus];
	}
	//
	BOOL hasMoreComing = (flags & kDNSServiceFlagsMoreComing) != 0;
	if (hasMoreComing == false) {
		[lookup didChangeTo_hasNoMoreComing]; // must dealloc service
	}
}
@end
