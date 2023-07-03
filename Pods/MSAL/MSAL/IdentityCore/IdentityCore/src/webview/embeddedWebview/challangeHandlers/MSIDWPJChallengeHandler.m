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

#import "MSIDWPJChallengeHandler.h"
#import "MSIDWorkPlaceJoinUtil.h"
#import "MSIDRegistrationInformation.h"
#import "MSIDWorkplaceJoinChallenge.h"
#import "MSIDWorkPlaceJoinConstants.h"

@implementation MSIDWPJChallengeHandler

+ (void)resetHandler { }

+ (BOOL)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                webview:(__unused WKWebView *)webview
#if TARGET_OS_IPHONE
       parentController:(__unused UIViewController *)parentViewController
#endif
                context:(id<MSIDRequestContext>)context
      completionHandler:(ChallengeCompletionHandler)completionHandler
{
    // See if this is a challenge for the WPJ cert.
    NSArray<NSData*> *distinguishedNames = challenge.protectionSpace.distinguishedNames;
    
    if ([self isWPJChallenge:distinguishedNames])
    {
#if TARGET_OS_IPHONE
#pragma unused(completionHandler)
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Ignoring WPJ challenge on iOS");
        return NO;
#else
        return [self handleWPJChallenge:challenge context:context completionHandler:completionHandler];
#endif
    }
    
    return NO;
}

+ (BOOL)shouldHandleChallenge:(NSURLAuthenticationChallenge *)challenge
{
    return [self isWPJChallenge:challenge.protectionSpace.distinguishedNames];
}

+ (BOOL)isWPJChallenge:(NSArray *)distinguishedNames
{
    for (NSData *distinguishedName in distinguishedNames)
    {
        NSString *distinguishedNameString = [[[NSString alloc] initWithData:distinguishedName encoding:NSISOLatin1StringEncoding] lowercaseString];
        if ([distinguishedNameString containsString:[kMSIDProtectionSpaceDistinguishedName lowercaseString]])
        {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)handleWPJChallenge:(NSURLAuthenticationChallenge *)challenge
                   context:(id<MSIDRequestContext>)context
         completionHandler:(ChallengeCompletionHandler)completionHandler
{
    MSIDWorkplaceJoinChallenge *wpjChallenge = [[MSIDWorkplaceJoinChallenge alloc] initWithURLChallenge:challenge];
    MSIDRegistrationInformation *info = [MSIDWorkPlaceJoinUtil getRegistrationInformation:context workplacejoinChallenge:wpjChallenge];
    if (!info || ![info isWorkPlaceJoined])
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Device is not workplace joined. host: %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
        
        // In other cert auth cases we send Cancel to ensure that we continue to get
        // auth challenges, however when we do that with WPJ we don't get the subsequent
        // enroll dialog *after* the failed clientTLS challenge.
        //
        // Using DefaultHandling will result in the OS not handing back client TLS
        // challenges for another ~60 seconds, behavior that looks broken in the
        // user CBA case, but here is masked by the user having to enroll their
        // device.
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return YES;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Responding to WPJ cert challenge. host: %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
    
    NSURLCredential *creds = [NSURLCredential credentialWithIdentity:info.securityIdentity
                                                        certificates:@[(__bridge id)info.certificateRef]
                                                         persistence:NSURLCredentialPersistenceNone];
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, creds);
    
    return YES;
}


@end
