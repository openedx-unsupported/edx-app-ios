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

#import "MSIDAADV2BrokerResponse.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDBrokerResponse+Internal.h"
#import "MSIDAADV2TokenResponse.h"
#import "MSIDAADAuthority.h"
#import "NSJSONSerialization+MSIDExtensions.h"

@implementation MSIDAADV2BrokerResponse

MSID_FORM_ACCESSOR(@"scope", scope);

- (instancetype)initWithDictionary:(NSDictionary *)form
                             error:(NSError **)error
{
    self = [super initWithDictionary:form error:error];

    if (self)
    {
        NSString *errorMetadataJSON = form[@"error_metadata"];
        if (errorMetadataJSON)
        {
            _errorMetadata = [NSJSONSerialization msidNormalizedDictionaryFromJsonData:[errorMetadataJSON dataUsingEncoding:NSUTF8StringEncoding] error:nil];
        }
    }

    return self;
}

- (void)initDerivedProperties
{
    self.tokenResponse = [[MSIDAADV2TokenResponse alloc] initWithJSONDictionary:_urlForm
                                                                          error:nil];
    self.msidAuthority = [[MSIDAADAuthority alloc] initWithURL:[NSURL URLWithString:self.authority] rawTenant:nil context:nil error:nil];
}

- (NSString *)errorCode
{
    return self.formDictionary[@"broker_error_code"];
}

- (NSString *)errorDomain
{
    return self.formDictionary[@"broker_error_domain"];
}

- (NSString *)oauthErrorCode
{
    return self.formDictionary[@"error"];
}

- (NSString *)errorDescription
{
    return self.formDictionary[@"error_description"];
}

- (NSString *)subError
{
    return self.formDictionary[@"suberror"];
}

- (NSDictionary *)httpHeaders
{
    // Currently broker may return http headers as both dictionary or string due to bug fix,
    // we need to handle both to support broker with/without the fix
    id headers = self.errorMetadata[@"http_response_headers"];
    
    if ([headers isKindOfClass:NSDictionary.class])
    {
        return headers;
    }
    
    if ([headers isKindOfClass:NSString.class])
    {
        return [NSDictionary msidDictionaryFromWWWFormURLEncodedString:headers];
    }
    
    return nil;
}

@end
