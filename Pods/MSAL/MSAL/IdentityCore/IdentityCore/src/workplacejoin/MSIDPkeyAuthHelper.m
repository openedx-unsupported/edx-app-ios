// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDPkeyAuthHelper.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "MSIDRegistrationInformation.h"
#import "MSIDWorkPlaceJoinUtil.h"
#import "MSIDError.h"
#import "MSIDJWTHelper.h"
#import "NSData+MSIDExtensions.h"

@implementation MSIDPkeyAuthHelper

+ (nullable NSString *)createDeviceAuthResponse:(nonnull NSURL *)authorizationServer
                                  challengeData:(nullable NSDictionary *)challengeData
                                        context:(nullable id<MSIDRequestContext>)context
{
    MSIDRegistrationInformation *info =
    [MSIDWorkPlaceJoinUtil getRegistrationInformation:context urlChallenge:nil];
    NSString *authToken = @"";
    NSString *challengeContext = challengeData ? [challengeData valueForKey:@"Context"] : @"";
    NSString *challengeVersion = challengeData ? [challengeData valueForKey:@"Version"] : @"";
    
    if (!info)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"No registration information found");
    }
    if (!challengeData)
    {
        // Error should have been logged before this where there is more information on why the challenge data was bad
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"PKeyAuth: Received PKeyAuth request with no challenge data.");
    }
    else if (![info isWorkPlaceJoined])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"PKeyAuth: Received PKeyAuth request but no WPJ info.");
    }
    else
    {
        NSString *certAuths = [challengeData valueForKey:@"CertAuthorities"];
        NSString *expectedThumbprint = [challengeData valueForKey:@"CertThumbprint"];
        
        if (certAuths)
        {
            NSString *issuerOU = [MSIDPkeyAuthHelper getOrgUnitFromIssuer:[info certificateIssuer]];
            if (![self isValidIssuer:certAuths keychainCertIssuer:issuerOU])
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"PKeyAuth Error: Certificate Authority specified by device auth request does not match certificate in keychain.");
                info = nil;
            }
        }
        else if (expectedThumbprint)
        {
            NSString *thumbprint = [[[info certificateData] msidSHA1] msidHexString];
            thumbprint = [[thumbprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];

            if (![expectedThumbprint isEqualToString:thumbprint])
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"PKeyAuth Error: Certificate Thumbprint does not match certificate in keychain.");
                info = nil;
            }
        }
        
        NSURLComponents *authorizationServerComponents = [[NSURLComponents alloc] initWithURL:authorizationServer resolvingAgainstBaseURL:NO];
        authorizationServerComponents.query = nil; // Strip out query parameters.
        if (info)
        {
            authToken = [NSString stringWithFormat:@"AuthToken=\"%@\",", [MSIDPkeyAuthHelper createDeviceAuthResponse:authorizationServerComponents.string nonce:[challengeData valueForKey:@"nonce"] identity:info]];
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Found WPJ Info and responded to PKeyAuth Request.");
        }
    }
    
    return [NSString stringWithFormat:@"PKeyAuth %@ Context=\"%@\", Version=\"%@\"", authToken, challengeContext, challengeVersion];
}


+ (NSString *)getOrgUnitFromIssuer:(NSString *)issuer
{
    NSString *regexString = @"[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    
    for (NSTextCheckingResult *myMatch in [regex matchesInString:issuer options:0 range:NSMakeRange(0, [issuer length])]){
        if (myMatch.numberOfRanges > 0) {
            NSRange matchedRange = [myMatch rangeAtIndex: 0];
            return [NSString stringWithFormat:@"OU=%@", [issuer substringWithRange: matchedRange]];
        }
    }
    
    return nil;
}

+ (BOOL)isValidIssuer:(NSString *)certAuths
   keychainCertIssuer:(NSString *)keychainCertIssuer
{
    NSString *regexString = @"OU=[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}";
    keychainCertIssuer = [keychainCertIssuer uppercaseString];
    certAuths = [certAuths uppercaseString];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    
    for (NSTextCheckingResult *myMatch in [regex matchesInString:certAuths options:0 range:NSMakeRange(0, [certAuths length])]){
        for (NSUInteger i = 0; i < myMatch.numberOfRanges; ++i)
        {
            NSRange matchedRange = [myMatch rangeAtIndex: i];
            NSString *text = [certAuths substringWithRange:matchedRange];
            if ([text isEqualToString:keychainCertIssuer]){
                return true;
            }
        }
    }
    
    return false;
}

+ (NSString *)createDeviceAuthResponse:(NSString *)audience
                                 nonce:(NSString *)nonce
                              identity:(MSIDRegistrationInformation *)identity
{
    if (!audience || !nonce)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"audience or nonce is nil in device auth request!");
        
        return nil;
    }
    NSArray *arrayOfStrings = @[[NSString stringWithFormat:@"%@", [[identity certificateData] base64EncodedStringWithOptions:0]]];
    NSDictionary *header = @{
                             @"alg" : @"RS256",
                             @"typ" : @"JWT",
                             @"x5c" : arrayOfStrings
                             };
    
    NSDictionary *payload = @{
                              @"aud" : audience,
                              @"nonce" : nonce,
                              @"iat" : [NSString stringWithFormat:@"%d", (CC_LONG)[[NSDate date] timeIntervalSince1970]]
                              };
    
    return [MSIDJWTHelper createSignedJWTforHeader:header payload:payload signingKey:[identity privateKey]];
}

@end
