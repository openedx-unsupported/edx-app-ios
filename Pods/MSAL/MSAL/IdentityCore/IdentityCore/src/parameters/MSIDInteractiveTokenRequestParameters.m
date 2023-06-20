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

#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDRequestParameters+Internal.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDClaimsRequest.h"

@implementation MSIDInteractiveTokenRequestParameters

- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                       authScheme:(MSIDAuthenticationScheme *)authScheme
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(NSOrderedSet<NSString *> *)oidScopes
             extraScopesToConsent:(NSOrderedSet<NSString *> *)extraScopesToConsent
                    correlationId:(NSUUID *)correlationId
                   telemetryApiId:(NSString *)telemetryApiId
                    brokerOptions:(MSIDBrokerInvocationOptions *)brokerOptions
                      requestType:(MSIDRequestType)requestType
              intuneAppIdentifier:(NSString *)intuneApplicationIdentifier
                            error:(NSError **)error
{
    self = [super initWithAuthority:authority
                         authScheme:authScheme
                        redirectUri:redirectUri
                           clientId:clientId
                             scopes:scopes
                         oidcScopes:oidScopes
                      correlationId:correlationId
                     telemetryApiId:telemetryApiId
                intuneAppIdentifier:intuneApplicationIdentifier
                        requestType:requestType
                              error:error];

    if (self)
    {
        _extraScopesToConsent = [extraScopesToConsent msidToString];
        _brokerInvocationOptions = brokerOptions;
        _enablePkce = YES;
    }

    return self;
}

- (void)setLoginHint:(NSString *)loginHint
{
    if ([_loginHint isEqualToString:loginHint]) return;
    
    _loginHint = loginHint;
    
    [self updateAppRequestMetadata:nil];
}

- (NSOrderedSet *)allAuthorizeRequestScopes
{
    NSMutableOrderedSet *requestScopes = [[self.allTokenRequestScopes msidScopeSet] mutableCopy];
    NSOrderedSet *extraScopes = [self.extraScopesToConsent msidScopeSet];

    if (extraScopes)
    {
        [requestScopes unionOrderedSet:extraScopes];
    }
    return requestScopes;
}

- (NSDictionary *)allAuthorizeRequestExtraParameters
{
    return [self allAuthorizeRequestExtraParametersWithMetadata:YES];
}

- (NSDictionary *)allAuthorizeRequestExtraParametersWithMetadata:(BOOL)includeMetadata
{
    NSMutableDictionary *authorizeParams = includeMetadata ? [[NSMutableDictionary alloc] initWithDictionary:self.appRequestMetadata] : [NSMutableDictionary new];
    
    if (self.extraAuthorizeURLQueryParameters && self.extraAuthorizeURLQueryParameters.count > 0)
    {
        [authorizeParams addEntriesFromDictionary:self.extraAuthorizeURLQueryParameters];
    }
    
    if (self.extraURLQueryParameters && self.extraURLQueryParameters.count > 0)
    {
        [authorizeParams addEntriesFromDictionary:self.extraURLQueryParameters];
    }
    
    return authorizeParams;
}

- (BOOL)validateParametersWithError:(NSError **)error
{
    BOOL result = [super validateParametersWithError:error];

    if (!result)
    {
        return NO;
    }
    
    __auto_type allAuthorizeRequestExtraParameters = [self allAuthorizeRequestExtraParametersWithMetadata:NO];
    if (self.claimsRequest.hasClaims && allAuthorizeRequestExtraParameters[MSID_OAUTH2_CLAIMS])
    {
        MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, @"Duplicate claims parameter is found in extraQueryParameters. Please remove it.", nil);
        result = NO;
    }

    return result;
}

- (void)updateAppRequestMetadata:(NSString *)homeAccountId
{
    [super updateAppRequestMetadata:homeAccountId];
    
    NSString *loginHint = self.loginHint;
    
    if (self.appRequestMetadata[MSID_CCS_HINT_KEY] == nil)
    {
        NSMutableDictionary *appRequestMetadata = [self.appRequestMetadata mutableCopy];
        appRequestMetadata[MSID_CCS_HINT_KEY] = [self ccsHintHeaderWithUpn:loginHint];
        self.appRequestMetadata = appRequestMetadata;
    }
}

@end
