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

#import "MSIDRequestParameters.h"
#import "MSIDRequestParameters+Internal.h"
#import "MSIDVersion.h"
#import "MSIDConstants.h"
#import "MSIDAuthority.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "MSIDConfiguration.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDClaimsRequest.h"
#import "MSIDAuthority+Internal.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDIntuneApplicationStateManager.h"
#import "MSIDAuthenticationScheme.h"

@implementation MSIDRequestParameters

#pragma mark - Init

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [self initDefaultSettings];
    }

    return self;
}

- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                       authScheme:(MSIDAuthenticationScheme *)authScheme
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(NSOrderedSet<NSString *> *)oidScopes
                    correlationId:(NSUUID *)correlationId
                   telemetryApiId:(NSString *)telemetryApiId
              intuneAppIdentifier:(NSString *)intuneApplicationIdentifier
                      requestType:(MSIDRequestType)requestType
                            error:(NSError **)error
{
    self = [super init];

    if (self)
    {
        [self initDefaultSettings];
        
        _authority = authority;
        _redirectUri = redirectUri;
        _clientId = clientId;
        _correlationId = correlationId ?: [NSUUID new];
        _telemetryApiId = telemetryApiId;
        _intuneApplicationIdentifier = intuneApplicationIdentifier;
        _requestType = requestType;

        if ([scopes intersectsOrderedSet:oidScopes])
        {
            NSString *errorMessage = [NSString stringWithFormat:@"%@ are reserved scopes and may not be specified in the acquire token call.", oidScopes];
            MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, errorMessage, correlationId);
            return nil;
        }
        else if (!_authority.supportsClientIDAsScope && [scopes containsObject:clientId])
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Passing clientId %@ as scope is not supported by %@. Please remove %@ from your scopes list", clientId, _authority.url, clientId];
            MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, errorMessage, correlationId);
            return nil;
        }

        _target = [scopes msidToString];

        if (oidScopes) _oidcScope = [oidScopes msidToString];
        
        _authScheme = authScheme;
    }

    return self;
}

- (void)initDefaultSettings
{
    _tokenExpirationBuffer = 300;
    _extendedLifetimeEnabled = NO;
    _logComponent = [MSIDVersion sdkName];
#if !EXCLUDE_FROM_MSALCPP
    _telemetryRequestId = [[MSIDTelemetry sharedInstance] generateRequestId];
#endif
    NSDictionary *metadata = [[NSBundle mainBundle] infoDictionary];

    NSString *appName = metadata[@"CFBundleDisplayName"];

    if (!appName)
    {
        appName = metadata[@"CFBundleName"];
    }

    NSString *appVer = metadata[@"CFBundleShortVersionString"];

    _appRequestMetadata = @{MSID_VERSION_KEY: [MSIDVersion sdkVersion],
                            MSID_APP_NAME_KEY: appName ? appName : @"",
                            MSID_APP_VER_KEY: appVer ? appVer : @""};
    
    _authScheme = [MSIDAuthenticationScheme new];
}

- (void)setAccountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
{
    if ([_accountIdentifier isEqual:accountIdentifier]) return;
    
    _accountIdentifier = accountIdentifier;
    
    [self updateAppRequestMetadata:nil];
}

#pragma mark - Helpers

- (NSURL *)tokenEndpoint
{
    if (!self.authority.metadata.tokenEndpoint)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"No token endpoint present");
        return nil;
    }
    
    NSURLComponents *tokenEndpoint = [NSURLComponents componentsWithURL:self.authority.metadata.tokenEndpoint resolvingAgainstBaseURL:NO];

    if (self.cloudAuthority)
    {
        tokenEndpoint.host = self.cloudAuthority.environment;
    }

    NSMutableDictionary *endpointQPs = [[NSDictionary msidDictionaryFromURLEncodedString:tokenEndpoint.percentEncodedQuery] mutableCopy];

    if (!endpointQPs)
    {
        endpointQPs = [NSMutableDictionary dictionary];
    }

    if (self.extraURLQueryParameters)
    {
        [endpointQPs addEntriesFromDictionary:self.extraURLQueryParameters];
    }

    tokenEndpoint.query = [endpointQPs msidURLEncode];
    return tokenEndpoint.URL;
}

- (void)setCloudAuthorityWithCloudHostName:(NSString *)cloudHostName
{
    if ([NSString msidIsStringNilOrBlank:cloudHostName]) return;
    NSError *cloudHostError = nil;
    
    _cloudAuthority = [self.authority authorityWithUpdatedCloudHostInstanceName:cloudHostName error:&cloudHostError];
    
    if (!_cloudAuthority && cloudHostError)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to create authority with cloud host name %@, and error %@, %ld", cloudHostName, cloudHostError.domain, (long)cloudHostError.code);
    }
    [self updateMSIDConfiguration];
}

- (void)setAuthority:(MSIDAuthority *)authority
{
    _authority = authority;
    [self updateMSIDConfiguration];
}

- (void)setCloudAuthority:(MSIDAuthority *)cloudAuthority
{
    _cloudAuthority = cloudAuthority;
    [self updateMSIDConfiguration];
}

- (void)setClientId:(NSString *)clientId
{
    _clientId = clientId;
    [self updateMSIDConfiguration];
}

- (void)setTarget:(NSString *)target
{
    _target = target;
    [self updateMSIDConfiguration];
}

- (NSString *)allTokenRequestScopes
{
    NSMutableOrderedSet *requestScopes = [[self.target msidScopeSet] mutableCopy];
    NSOrderedSet *oidcScopes = [self.oidcScope msidScopeSet];

    if (oidcScopes)
    {
        [requestScopes unionOrderedSet:oidcScopes];
    }
    return [requestScopes msidToString];
}

- (void)setAuthScheme:(MSIDAuthenticationScheme *)authScheme
{
    _authScheme = authScheme;
    [self updateMSIDConfiguration];
}

- (void)updateMSIDConfiguration
{
    MSIDAuthority *authority = self.cloudAuthority ? self.cloudAuthority : self.authority;

    MSIDConfiguration *config = [[MSIDConfiguration alloc] initWithAuthority:authority
                                                                 redirectUri:self.redirectUri
                                                                    clientId:self.clientId
                                                                      target:self.target];
    
    config.applicationIdentifier = [MSIDIntuneApplicationStateManager intuneApplicationIdentifierForAuthority:authority
                                                                                                appIdentifier:self.intuneApplicationIdentifier];
    config.authScheme = self.authScheme;
    _msidConfiguration = config;
}

- (MSIDConfiguration *)msidConfiguration
{
    if (!_msidConfiguration)
    {
        [self updateMSIDConfiguration];
    }

    return _msidConfiguration;
}

- (void)updateAppRequestMetadata:(NSString *)homeAccountId
{
    MSIDAccountIdentifier *accountIdentifier = self.accountIdentifier;
    
    if (![NSString msidIsStringNilOrBlank:homeAccountId])
    {
        accountIdentifier = [[MSIDAccountIdentifier alloc] initWithDisplayableId:nil homeAccountId:homeAccountId];
    }
    
    NSMutableDictionary *appRequestMetadata = [self.appRequestMetadata mutableCopy];
    [appRequestMetadata removeObjectForKey:MSID_CCS_HINT_KEY];
    
    NSString *uid = accountIdentifier.uid;
    NSString *utid = accountIdentifier.utid;
    
    if (![NSString msidIsStringNilOrBlank:uid] && ![NSString msidIsStringNilOrBlank:utid])
    {
        NSString *oidHeader = [NSString stringWithFormat:@"Oid:%@@%@", uid, utid];
        appRequestMetadata[MSID_CCS_HINT_KEY] = oidHeader;
    }
    else
    {
        appRequestMetadata[MSID_CCS_HINT_KEY] = [self ccsHintHeaderWithUpn:accountIdentifier.displayableId];
    }
    
    self.appRequestMetadata = appRequestMetadata;
}

#pragma mark - Validate

- (BOOL)validateParametersWithError:(NSError **)error
{
    if (!self.authority)
    {
        MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, @"Missing authority parameter", self.correlationId);
        return NO;
    }

    if (!self.redirectUri)
    {
        MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, @"Missing redirectUri parameter", self.correlationId);
        return NO;
    }

    if (!self.clientId)
    {
        MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, @"Missing clientId parameter", self.correlationId);
        return NO;
    }

    if (!self.target)
    {
        MSIDFillAndLogError(error, MSIDErrorInvalidDeveloperParameter, @"Missing target parameter", self.correlationId);
        return NO;
    }

    return YES;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone*)zone
{
    __auto_type parameters = [[MSIDRequestParameters allocWithZone:zone] init];
    parameters->_authority = [_authority copyWithZone:zone];
    parameters->_providedAuthority = [_providedAuthority copyWithZone:zone];
    parameters->_cloudAuthority = [_cloudAuthority copyWithZone:zone];
    parameters->_redirectUri = [_redirectUri copyWithZone:zone];
    parameters->_clientId = [_clientId copyWithZone:zone];
    parameters->_target = [_target copyWithZone:zone];
    parameters->_oidcScope = [_oidcScope copyWithZone:zone];
    parameters->_accountIdentifier = [_accountIdentifier copyWithZone:zone];
    parameters->_validateAuthority = _validateAuthority;
    parameters->_extraTokenRequestParameters = [_extraTokenRequestParameters copyWithZone:zone];
    parameters->_extraURLQueryParameters = [_extraURLQueryParameters copyWithZone:zone];
    parameters->_tokenExpirationBuffer = _tokenExpirationBuffer;
    parameters->_extendedLifetimeEnabled = _extendedLifetimeEnabled;
    parameters->_instanceAware = _instanceAware;
    parameters->_intuneApplicationIdentifier = [_intuneApplicationIdentifier copyWithZone:zone];
    parameters->_requestType = _requestType;
    parameters->_correlationId = [_correlationId copyWithZone:zone];
    parameters->_logComponent = [_logComponent copyWithZone:zone];
    parameters->_telemetryRequestId = [_telemetryRequestId copyWithZone:zone];
    parameters->_appRequestMetadata = [_appRequestMetadata copyWithZone:zone];
    parameters->_telemetryApiId = [_telemetryApiId copyWithZone:zone];
    parameters->_claimsRequest = [_claimsRequest copyWithZone:zone];
    parameters->_clientCapabilities = [_clientCapabilities copyWithZone:zone];
    parameters->_msidConfiguration = [_msidConfiguration copyWithZone:zone];
    parameters->_keychainAccessGroup = [_keychainAccessGroup copyWithZone:zone];

    return parameters;
}

#pragma mark - Private

- (NSString *)ccsHintHeaderWithUpn:(NSString *)upn
{
    if (![NSString msidIsStringNilOrBlank:upn])
    {
        return [NSString stringWithFormat:@"UPN:%@", upn];
    }
    
    return nil;
}

@end
