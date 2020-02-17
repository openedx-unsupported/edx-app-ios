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

#import "MSIDAADV1BrokerResponse.h"
#import "MSIDAADV1TokenResponse.h"
#import "MSIDBrokerResponse+Internal.h"
#import "MSIDAADAuthority.h"

@implementation MSIDAADV1BrokerResponse

MSID_FORM_ACCESSOR(@"resource", resource);
MSID_FORM_ACCESSOR(@"http_headers", httpHeaders);
MSID_FORM_ACCESSOR(MSID_OAUTH2_ERROR_DESCRIPTION, errorDescription);
MSID_FORM_ACCESSOR(MSID_OAUTH2_SUB_ERROR, subError);
MSID_FORM_ACCESSOR(@"user_id", userId);

- (instancetype)initWithDictionary:(NSDictionary *)form
                             error:(NSError **)error
{
    self = [super initWithDictionary:form error:error];

    if (self)
    {
        self.tokenResponse = [[MSIDAADV1TokenResponse alloc] initWithJSONDictionary:form
                                                                              error:error];
    }

    return self;
}

- (void)initDerivedProperties
{
    self.tokenResponse = [[MSIDAADV1TokenResponse alloc] initWithJSONDictionary:_urlForm
                                                                          error:nil];
    self.msidAuthority = [[MSIDAADAuthority alloc] initWithURL:[NSURL URLWithString:self.authority] rawTenant:nil context:nil error:nil];
}

- (NSString *)oauthErrorCode
{
    if (_urlForm[@"protocol_code"])
    {
        return _urlForm[@"protocol_code"];
    }

    return _urlForm[@"code"];
}

- (NSString *)target
{
    return _urlForm[@"resource"];
}

- (BOOL)accessTokenInvalidForResponse
{
    // A bug in previous versions of broker would override the provided authority in some cases with
    // common. If the intended tenant was something other then common then the access token may
    // be bad, so clear it out. We will force a token refresh later.
    NSArray *pathComponents = [[NSURL URLWithString:self.authority] pathComponents];
    NSString *tenant = (pathComponents.count > 1) ? pathComponents[1] : nil;
    BOOL fValidTenant = self.validAuthority != nil || [tenant isEqualToString:@"common"];
    return !fValidTenant;
}

@end
