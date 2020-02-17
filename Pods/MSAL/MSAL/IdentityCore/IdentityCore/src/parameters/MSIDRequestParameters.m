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
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(NSOrderedSet<NSString *> *)oidScopes
                    correlationId:(NSUUID *)correlationId
                   telemetryApiId:(NSString *)telemetryApiId
              intuneAppIdentifier:(NSString *)intuneApplicationIdentifier
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
    }

    return self;
}

- (void)initDefaultSettings
{
    _tokenExpirationBuffer = 300;
    _extendedLifetimeEnabled = NO;
    _logComponent = [MSIDVersion sdkName];
    _telemetryRequestId = [[MSIDTelemetry sharedInstance] generateRequestId];

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
}

#pragma mark - Helpers

- (NSURL *)tokenEndpoint
{
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

- (void)updateMSIDConfiguration
{
    MSIDAuthority *authority = self.cloudAuthority ? self.cloudAuthority : self.authority;

    MSIDConfiguration *config = [[MSIDConfiguration alloc] initWithAuthority:authority
                                                                 redirectUri:self.redirectUri
                                                                    clientId:self.clientId
                                                                      target:self.target];
    
    config.applicationIdentifier = [MSIDIntuneApplicationStateManager intuneApplicationIdentifierForAuthority:authority
                                                                                                appIdentifier:self.intuneApplicationIdentifier];
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

@end
