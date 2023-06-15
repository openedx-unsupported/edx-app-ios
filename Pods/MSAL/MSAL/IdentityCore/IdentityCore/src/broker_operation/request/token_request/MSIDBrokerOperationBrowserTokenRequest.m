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

#import "MSIDBrokerOperationBrowserTokenRequest.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDAADAuthority.h"
#import "MSIDAuthority+Internal.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "NSURL+MSIDAADUtils.h"
#import "MSIDAADNetworkConfiguration.h"

@implementation MSIDBrokerOperationBrowserTokenRequest

- (instancetype)initWithRequest:(NSURL *)requestURL
                        headers:(NSDictionary *)headers
                           body:(NSData *)httpBody
               bundleIdentifier:(NSString *)bundleIdentifier
               requestValidator:(id<MSIDBrowserRequestValidating>)requestValidator
           useSSOCookieFallback:(BOOL)useSSOCookieFallback
                          error:(NSError **)error
{
    self = [super init];
    if (self)
    {
        if (![requestURL isKindOfClass:[NSURL class]])
        {
            if (error)
            {
               NSString *errorMessage = [NSString stringWithFormat:@"Failed to create browser operation request due to invalid request url %@",_PII_NULLIFY(requestURL)];
               *error = MSIDCreateError(MSIDErrorDomain,MSIDErrorInvalidInternalParameter,errorMessage,nil, nil, nil, nil, nil, YES);
            }
                  
           return nil;
        }
        
        _requestURL = requestURL;
        
        if (![requestValidator shouldHandleURL:_requestURL])
        {
            if (error)
            {
                NSString *errorMessage = [NSString stringWithFormat:@"Failed to create browser operation request, %@ is not authorize request", _PII_NULLIFY([requestURL absoluteString])];
                *error = MSIDCreateError(MSIDErrorDomain,MSIDErrorInvalidInternalParameter,errorMessage,nil, nil, nil, nil, nil, YES);
            }
                   
            return nil;
        }
        
        _useSSOCookieFallback = useSSOCookieFallback;
        _headers = headers;
        _httpBody = httpBody;
        _bundleIdentifier = bundleIdentifier;
        
        MSIDAADAuthority *authority = [[MSIDAADAuthority alloc] initWithURL:_requestURL rawTenant:nil context:nil error:error];
        
        if (!authority)
        {
            return nil;
        }
        
        _authority = authority;
        __auto_type tokenEndpoint = [MSIDAADNetworkConfiguration.defaultConfiguration.endpointProvider oauth2TokenEndpointWithUrl:_authority.url];
        
        authority.metadata = [MSIDOpenIdProviderMetadata new];
        authority.metadata.tokenEndpoint = tokenEndpoint;
        
        _correlationId = [NSUUID UUID];
    }
    
    return self;
}

#pragma mark - MSIDBaseBrokerOperationRequest

+ (NSString *)operation
{
    return MSID_JSON_TYPE_OPERATION_REQUEST_GET_PRT;
}

- (NSString *)logInfo
{
    return [NSString stringWithFormat:@"(requestUrl=%@, bundle_identifier=%@)", self.requestURL, self.bundleIdentifier];
}
@end
