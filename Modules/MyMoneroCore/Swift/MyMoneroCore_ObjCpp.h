//
//  MyMoneroCore_ObjCpp.h
//  MyMonero
//
//  Created by Paul Shapiro on 11/22/17.
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
#import <Foundation/Foundation.h>
//
@interface Monero_DecodedAddress_RetVals: NSObject

@property (nonatomic, copy) NSString *errStr_orNil;

@property (nonatomic, copy) NSString *pub_viewKey_NSString;
@property (nonatomic, copy) NSString *pub_spendKey_NSString;
@property (nonatomic) BOOL isSubaddress;
@property (nonatomic, copy) NSString *paymentID_NSString_orNil;

@end
//
@interface MyMoneroCore_ObjCpp : NSObject
//
// Return value dictionary keys
+ (NSString *)retValDictKey__ErrStr;
+ (NSString *)retValDictKey__Value; // used for single value returns… you should force-cast the type… e.g. "as! String" for -mnemonicStringFromSeedHex:…
//
//
+ (Monero_DecodedAddress_RetVals *)decodedAddress:(NSString *)addressString isTestnet:(BOOL)isTestnet;
+ (BOOL)isSubAddress:(NSString *)addressString isTestnet:(BOOL)isTestnet;
+ (BOOL)isIntegratedAddress:(NSString *)addressString isTestnet:(BOOL)isTestnet;
//
//+ (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID isTestnet:(BOOL)isTestnet;
//+ (NSString *)new_integratedAddrFromStdAddr:(NSString *)std_address_NSString andShortPID:(NSString *)short_paymentID; // mainnet
//
@end
