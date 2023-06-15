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

#import "MSIDAADEndpointProvider.h"
#import "MSIDAADNetworkConfiguration.h"

@implementation MSIDAADEndpointProvider

#pragma mark - MSIDEndpointProviderProtocol

- (NSURL *)oauth2AuthorizeEndpointWithUrl:(NSURL *)baseUrl
{
    __auto_type apiVersion = [self aadApiVersionWithDelimiter];
    
    return [baseUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"/oauth2/%@authorize", apiVersion]];
}

- (NSURL *)oauth2TokenEndpointWithUrl:(NSURL *)baseUrl
{
    __auto_type apiVersion = [self aadApiVersionWithDelimiter];
    
    return [baseUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"/oauth2/%@token", apiVersion]];
}

- (NSURL *)drsDiscoveryEndpointWithDomain:(NSString *)domain adfsType:(MSIDDRSType)type
{
    if (type == MSIDDRSTypeOnPrem)
    {
        return [NSURL URLWithString:
                [NSString stringWithFormat:@"https://enterpriseregistration.%@/enrollmentserver/contract", domain.lowercaseString]];
    }
    else if (type == MSIDDRSTypeInCloud)
    {
        return [NSURL URLWithString:
                [NSString stringWithFormat:@"https://enterpriseregistration.windows.net/%@/enrollmentserver/contract", domain.lowercaseString]];
    }
    
    return nil;
}

- (NSURL *)webFingerDiscoveryEndpointWithIssuer:(NSURL *)issuer
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/.well-known/webfinger", issuer.host]];
}

- (NSURL *)openIdConfigurationEndpointWithUrl:(NSURL *)baseUrl
{
    if (!baseUrl) return nil;
    
    __auto_type apiVersion = [self aadApiVersionWithDelimiter];
    __auto_type path = [NSString stringWithFormat:@"%@%@", apiVersion, MSID_OPENID_CONFIGURATION_SUFFIX];
    
    return [baseUrl URLByAppendingPathComponent:path];
}

- (NSURL *)aadAuthorityDiscoveryEndpointWithHost:(NSString *)host
{
    __auto_type trustedAuthority = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://%@", host]];
    return [trustedAuthority URLByAppendingPathComponent:MSID_OAUTH2_INSTANCE_DISCOVERY_SUFFIX];
}

#pragma mark - Private

- (NSString *)aadApiVersionWithDelimiter
{
    __auto_type apiVersion = MSIDAADNetworkConfiguration.defaultConfiguration.aadApiVersion ?: @"";
    __auto_type delimiter = MSIDAADNetworkConfiguration.defaultConfiguration.aadApiVersion ? @"/" : @"";
    
    return [NSString stringWithFormat:@"%@%@", apiVersion, delimiter];
}

@end
