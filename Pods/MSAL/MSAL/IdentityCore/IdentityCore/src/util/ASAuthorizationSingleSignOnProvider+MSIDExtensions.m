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

#if MSID_ENABLE_SSO_EXTENSION
#import "ASAuthorizationSingleSignOnProvider+MSIDExtensions.h"
#import "MSIDConstants.h"
#import "MSIDBrokerOperationRequest.h"
#import "MSIDRequestParameters.h"
#import "NSDictionary+MSIDQueryItems.h"
#import "ASAuthorizationController+MSIDExtensions.h"

@implementation ASAuthorizationSingleSignOnProvider (MSIDExtensions)

+ (ASAuthorizationSingleSignOnProvider *)msidSharedProvider
{
    NSURL *url = [NSURL URLWithString:MSID_DEFAULT_AAD_AUTHORITY];
    return [ASAuthorizationSingleSignOnProvider authorizationProviderWithIdentityProviderURL:url];
}

- (ASAuthorizationSingleSignOnRequest *)createSSORequestWithOperationRequest:(MSIDBrokerOperationRequest *)operationRequest
                                                           requestParameters:(MSIDRequestParameters *)requestParameters
                                                                  requiresUI:(BOOL)requiresUI
                                                                       error:(NSError **)error
{
    [MSIDBrokerOperationRequest fillRequest:operationRequest
                        keychainAccessGroup:requestParameters.keychainAccessGroup
                             clientMetadata:requestParameters.appRequestMetadata
                                    context:requestParameters];
    
    ASAuthorizationSingleSignOnRequest *ssoRequest = [self createRequest];
    ssoRequest.requestedOperation = [operationRequest.class operation];
    [self.class setRequiresUI:requiresUI forRequest:ssoRequest];
    
    NSDictionary *jsonDictionary = [operationRequest jsonDictionary];
    
    if (!jsonDictionary)
    {
        NSError *ssoError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, [NSString stringWithFormat:@"Failed to serialize SSO request dictionary for %@", [[operationRequest class] operation]], nil, nil, nil, requestParameters.correlationId, nil, YES);
        if (error) *error = ssoError;
        return nil;
    }
    
    NSArray<NSURLQueryItem *> *queryItems = [jsonDictionary msidQueryItems];
    ssoRequest.authorizationOptions = queryItems;
    return ssoRequest;
}

+ (void)setRequiresUI:(BOOL)requiresUI forRequest:(ASAuthorizationSingleSignOnRequest *)ssoRequest
{    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 120000
    if (@available(iOS 15.0, macOS 12.0, *))
    {
        ssoRequest.userInterfaceEnabled = requiresUI;
    }
#endif
}

@end
#endif
