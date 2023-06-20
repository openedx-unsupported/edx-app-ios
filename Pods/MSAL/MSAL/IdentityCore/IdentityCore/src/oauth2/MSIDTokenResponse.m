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

#import "MSIDTokenResponse.h"
#import "MSIDHelpers.h"
#import "MSIDRefreshableToken.h"
#import "MSIDBaseToken.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDTokenResponse+Internal.h"
#import "MSIDProviderType.h"
#import "MSIDConstants.h"

@implementation MSIDTokenResponse

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                          refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                 error:(NSError **)error
{
    self = [self initWithJSONDictionary:json error:error];
    if (self)
    {
        if (token && [NSString msidIsStringNilOrBlank:_refreshToken])
        {
            _refreshToken = token.refreshToken;
        }
    }

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Token response: access token %@, refresh token %@, scope %@, state %@, id token %@, error %@, error description %@", _PII_NULLIFY(self.accessToken), _PII_NULLIFY(self.refreshToken), self.scope, self.state, _PII_NULLIFY(self.idToken), self.error, self.errorDescription];
}

- (void)setAdditionalServerInfo:(NSDictionary *)additionalServerInfo
{
    NSArray *knownFields = @[MSID_OAUTH2_ERROR,
                             MSID_OAUTH2_ERROR_DESCRIPTION,
                             MSID_OAUTH2_ACCESS_TOKEN,
                             MSID_OAUTH2_TOKEN_TYPE,
                             MSID_OAUTH2_REFRESH_TOKEN,
                             MSID_OAUTH2_SCOPE,
                             MSID_OAUTH2_STATE,
                             MSID_OAUTH2_ID_TOKEN,
                             MSID_OAUTH2_EXPIRES_IN,
                             MSID_OAUTH2_EXPIRES_ON];
    
    NSDictionary *additionalInfo = [additionalServerInfo msidDictionaryByRemovingFields:knownFields];
    _additionalServerInfo = additionalInfo.count > 0 ? additionalInfo : nil;
}

- (void)setIdToken:(NSString *)idToken
{
    if (![NSString msidIsStringNilOrBlank:idToken])
    {
        _idToken = idToken;
        
        NSError *localError;
        _idTokenObj = [self tokenClaimsFromRawIdToken:idToken error:&localError];
        if (idToken && localError)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, nil, @"Failed to init id token claims in %@, error: %@", self.class, MSID_PII_LOG_MASKABLE(localError));
        }
    }
    else
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Id token was set to nil in token response!");
        _idToken = nil;
        _idTokenObj = nil;
    }
}

#pragma mark - Derived properties

- (NSDate *)expiryDate
{
    if (self.expiresOn) return [NSDate dateWithTimeIntervalSince1970:self.expiresOn];
    if (self.expiresIn) return [NSDate dateWithTimeIntervalSinceNow:self.expiresIn];

    return nil;
}

- (BOOL)isMultiResource
{
    return YES;
}

- (NSString *)target
{
    return self.scope;
}

- (MSIDAccountType)accountType
{
    return MSIDAccountTypeOther;
}

- (MSIDErrorCode)oauthErrorCode
{
    return MSIDErrorCodeForOAuthError(self.error, MSIDErrorServerOauth);
}

+ (MSIDProviderType)providerType
{
    @throw MSIDException(MSIDGenericException, @"Abstract method was invoked.", nil);
}

#pragma mark - Protected

- (MSIDIdTokenClaims *)tokenClaimsFromRawIdToken:(NSString *)rawIdToken error:(NSError **)error
{
    return [[MSIDIdTokenClaims alloc] initWithRawIdToken:rawIdToken error:error];
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super init];
    if (self)
    {
        if (!json)
        {
            if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Attempt to initialize token response with nil json", nil, nil, nil, nil, nil, YES);
            
            return nil;
        }
        
        _accessToken = [json msidStringObjectForKey:MSID_OAUTH2_ACCESS_TOKEN];
        _refreshToken = [json msidStringObjectForKey:MSID_OAUTH2_REFRESH_TOKEN];
        _expiresIn = [json msidIntegerObjectForKey:MSID_OAUTH2_EXPIRES_IN];
        _expiresOn = [json msidIntegerObjectForKey:MSID_OAUTH2_EXPIRES_ON];
        _tokenType = [json msidStringObjectForKey:MSID_OAUTH2_TOKEN_TYPE];
        _requestConf = [json msidStringObjectForKey:MSID_OAUTH2_REQUEST_CONFIRMATION];
        _scope = [json msidStringObjectForKey:MSID_OAUTH2_SCOPE];
        _state = [json msidStringObjectForKey:MSID_OAUTH2_STATE];
        [self setIdToken:[json msidStringObjectForKey:MSID_OAUTH2_ID_TOKEN]];
        _error = [json msidStringObjectForKey:MSID_OAUTH2_ERROR];
        _errorDescription = [[json msidStringObjectForKey:MSID_OAUTH2_ERROR_DESCRIPTION] msidURLDecode];
        _clientAppVersion = [json msidStringObjectForKey:MSID_BROKER_CLIENT_APP_VERSION_KEY];
        [self setAdditionalServerInfo:json];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    if (self.additionalServerInfo) [json addEntriesFromDictionary:self.additionalServerInfo];
    
    if (self.error)
    {
        json[MSID_OAUTH2_ERROR] = self.error;
        json[MSID_OAUTH2_ERROR_DESCRIPTION] = [self.errorDescription msidURLEncode];
    }
    else
    {
        json[MSID_OAUTH2_ACCESS_TOKEN] = self.accessToken;
        json[MSID_OAUTH2_REFRESH_TOKEN] = self.refreshToken;
        json[MSID_OAUTH2_EXPIRES_IN] = [@(self.expiresIn) stringValue];
        json[MSID_OAUTH2_EXPIRES_ON] = [@(self.expiresOn) stringValue];
        json[MSID_OAUTH2_TOKEN_TYPE] = self.tokenType;
        json[MSID_OAUTH2_SCOPE] = self.scope;
        json[MSID_OAUTH2_ID_TOKEN] = self.idToken;
        json[MSID_OAUTH2_REQUEST_CONFIRMATION] = self.requestConf;
    }
    
    json[MSID_OAUTH2_STATE] = self.state;
    json[MSID_PROVIDER_TYPE_JSON_KEY] = MSIDProviderTypeToString(self.class.providerType);
    json[MSID_BROKER_CLIENT_APP_VERSION_KEY] = self.clientAppVersion;
    
    return json;
}

@end
