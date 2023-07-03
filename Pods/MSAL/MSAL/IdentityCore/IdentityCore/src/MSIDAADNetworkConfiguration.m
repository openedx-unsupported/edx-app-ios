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

#import "MSIDAADNetworkConfiguration.h"
#import "MSIDAADEndpointProvider.h"
#import "MSIDConstants.h"
#import "MSIDVersion.h"

static MSIDAADNetworkConfiguration *s_defaultConfiguration;
static NSSet<NSString *> *s_trustedHostList;

@implementation MSIDAADNetworkConfiguration

+ (void)initialize
{
    if (self == [MSIDAADNetworkConfiguration self])
    {
        s_defaultConfiguration = [MSIDAADNetworkConfiguration new];
        
        s_trustedHostList = [NSSet setWithObjects:MSIDTrustedAuthority,
                             MSIDTrustedAuthorityUS,
                             MSIDTrustedAuthorityChina,
                             MSIDTrustedAuthorityChina2,
                             MSIDTrustedAuthorityGermany,
                             MSIDTrustedAuthorityWorldWide,
                             MSIDTrustedAuthorityUSGovernment,
                             MSIDTrustedAuthorityCloudGovApi, nil];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _endpointProvider = [MSIDAADEndpointProvider new];
        _aadAuthorityDiscoveryApiVersion = @"1.1";
        _drsDiscoveryApiVersion = @"1.0";
        _aadApiVersion = [MSIDVersion aadApiVersion];
    }
    
    return self;
}

+ (MSIDAADNetworkConfiguration *)defaultConfiguration
{
    return s_defaultConfiguration;
}

+ (void)setDefaultConfiguration:(MSIDAADNetworkConfiguration *)defaultConfiguration
{
    s_defaultConfiguration = defaultConfiguration;
}

- (BOOL)isAADPublicCloud:(NSString *)host
{
    if (!host) return NO;
    
    return [s_trustedHostList containsObject:host];
}

- (NSSet<NSString *> *)trustedHosts
{
    return s_trustedHostList;
}

@end
