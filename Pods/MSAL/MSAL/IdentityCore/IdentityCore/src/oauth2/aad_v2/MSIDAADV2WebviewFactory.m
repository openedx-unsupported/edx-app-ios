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

#import "MSIDAADV2WebviewFactory.h"
#import "MSIDAuthorizeWebRequestConfiguration.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDWebWPJResponse.h"
#import "MSIDWebAADAuthCodeResponse.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDSignoutWebRequestConfiguration.h"
#import "MSIDInteractiveTokenRequestParameters.h"

@implementation MSIDAADV2WebviewFactory

- (NSMutableDictionary<NSString *, NSString *> *)authorizationParametersFromRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                                                                                         pkce:(MSIDPkce *)pkce
                                                                                 requestState:(NSString *)state
{
    NSMutableDictionary<NSString *, NSString *> *result = [super authorizationParametersFromRequestParameters:parameters
                                                                                                         pkce:pkce
                                                                                                 requestState:state];
    
    result[MSID_OAUTH2_CLIENT_INFO] = @"1";
    return result;
}

- (NSDictionary<NSString *, NSString *> *)metadataFromRequestParameters:(MSIDInteractiveRequestParameters *)parameters
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result addEntriesFromDictionary:[super metadataFromRequestParameters:parameters]];
    
    result[MSID_OAUTH2_LOGIN_REQ] = parameters.accountIdentifier.uid;
    result[MSID_OAUTH2_DOMAIN_REQ] = parameters.accountIdentifier.utid;
    
    return result;
}

@end
