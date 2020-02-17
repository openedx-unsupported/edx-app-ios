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

@implementation MSIDTokenResponse

// Default properties for an error response
MSID_JSON_ACCESSOR(MSID_OAUTH2_ERROR, error)
MSID_JSON_ACCESSOR(MSID_OAUTH2_ERROR_DESCRIPTION, errorDescription)

// Default properties for a successful response
MSID_JSON_ACCESSOR(MSID_OAUTH2_ACCESS_TOKEN, accessToken)
MSID_JSON_ACCESSOR(MSID_OAUTH2_TOKEN_TYPE, tokenType)
MSID_JSON_RW(MSID_OAUTH2_REFRESH_TOKEN, refreshToken, setRefreshToken)
MSID_JSON_ACCESSOR(MSID_OAUTH2_SCOPE, scope)
MSID_JSON_ACCESSOR(MSID_OAUTH2_STATE, state)
MSID_JSON_RW(MSID_OAUTH2_ID_TOKEN, idToken, setIdToken)

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                          refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                 error:(NSError **)error
{
    self = [self initWithJSONDictionary:json error:error];
    if (self)
    {
        if (token && [NSString msidIsStringNilOrBlank:self.refreshToken])
        {
            self.refreshToken = token.refreshToken;
        }
    }
    
    return self;
}

- (id)initWithJSONDictionary:(NSDictionary *)json error:(NSError *__autoreleasing *)error
{
    if (!(self = [super initWithJSONDictionary:json error:error]))
    {
        return nil;
    }
    
    [self initIdToken:error];
    return self;
}

- (BOOL)initIdToken:(NSError *__autoreleasing *)error
{
    if (![NSString msidIsStringNilOrBlank:self.idToken])
    {
        self.idTokenObj = [[MSIDIdTokenClaims alloc] initWithRawIdToken:self.idToken error:error];
        return self.idTokenObj != nil;
    }
    return YES;
}

- (NSInteger)expiresIn
{
    id expiresInObj = _json[MSID_OAUTH2_EXPIRES_IN];
    NSInteger expiresIn = [MSIDHelpers msidIntegerValue:expiresInObj];
    
    if (!expiresIn && expiresInObj)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Unparsable time - The response value for the access token expiration cannot be parsed: %@", expiresInObj);
    }
    
    return expiresIn;
}

- (void)setExpiresIn:(NSInteger)expiresIn
{
    NSString *expiresInString = [NSString stringWithFormat:@"%ld", (long)expiresIn];
    _json[MSID_OAUTH2_EXPIRES_IN] = expiresInString;
}

- (NSDate *)expiryDate
{
    NSInteger expiresIn = self.expiresIn;
    
    if (!expiresIn)
    {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSinceNow:expiresIn];
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

- (NSDictionary *)additionalServerInfo
{
    NSArray *knownFields = @[MSID_OAUTH2_ERROR,
                             MSID_OAUTH2_ERROR_DESCRIPTION,
                             MSID_OAUTH2_ACCESS_TOKEN,
                             MSID_OAUTH2_TOKEN_TYPE,
                             MSID_OAUTH2_REFRESH_TOKEN,
                             MSID_OAUTH2_SCOPE,
                             MSID_OAUTH2_STATE,
                             MSID_OAUTH2_ID_TOKEN,
                             MSID_OAUTH2_EXPIRES_IN];
    
    NSDictionary *additionalInfo = [_json dictionaryByRemovingFields:knownFields];
    if (additionalInfo.count > 0)
    {
        return additionalInfo;
    }
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Token response: access token %@, refresh token %@, scope %@, state %@, id token %@, error %@, error description %@", _PII_NULLIFY(self.accessToken), _PII_NULLIFY(self.refreshToken), self.scope, self.state, _PII_NULLIFY(self.idToken), self.error, self.errorDescription];
}

@end
