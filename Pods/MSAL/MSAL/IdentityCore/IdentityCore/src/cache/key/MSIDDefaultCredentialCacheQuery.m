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

#import "MSIDDefaultCredentialCacheQuery.h"

@implementation MSIDDefaultCredentialCacheQuery

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _targetMatchingOptions = MSIDExactStringMatch;
        _clientIdMatchingOptions = MSIDExactStringMatch;
        _matchAnyCredentialType = NO;
    }

    return self;
}

- (NSString *)account
{
    if (self.homeAccountId && self.environment)
    {
        return [self accountIdWithHomeAccountId:self.homeAccountId environment:self.environment];
    }

    return nil;
}

- (NSString *)service
{
    if (self.matchAnyCredentialType)
    {
        return nil;
    }

    switch (self.credentialType)
    {
        case MSIDAccessTokenType:
        {
            return [self serviceForAccessToken];
        }
        case MSIDAccessTokenWithAuthSchemeType:
        {
            return [self serviceForAccessToken];
        }
        case MSIDPrimaryRefreshTokenType:
        case MSIDRefreshTokenType:
        {
            return [self serviceForRefreshToken];
        }
        case MSIDIDTokenType:
        {
            return [self serviceForIDToken];
        }
        case MSIDLegacyIDTokenType:
        {
            return [self serviceForLegacyIDToken];
        }
        default:
            break;
    }

    return nil;
}

- (NSString *)serviceForAccessToken
{
    if (self.queryClientId
        && self.realm
        && self.target
        && self.targetMatchingOptions == MSIDExactStringMatch)
    {
        return [self serviceWithType:self.credentialType clientID:self.queryClientId realm:self.realm applicationIdentifier:self.applicationIdentifier target:self.target appKey:self.appKey tokenType:self.tokenType requestedClaims:self.requestedClaims];
    }

    return nil;
}

- (NSString *)serviceForRefreshToken
{
    if (self.queryClientId)
    {
        return [self serviceWithType:self.credentialType clientID:self.queryClientId realm:nil applicationIdentifier:nil target:nil appKey:self.appKey tokenType:self.tokenType requestedClaims:nil];
    }

    return nil;
}

- (NSString *)serviceForIDToken
{
    if (self.clientId && self.realm)
    {
        return [self serviceWithType:MSIDIDTokenType clientID:self.clientId realm:self.realm applicationIdentifier:nil target:nil appKey:self.appKey tokenType:self.tokenType requestedClaims:nil];
    }
    
    return nil;
}

- (NSString *)serviceForLegacyIDToken
{
    if (self.clientId && self.realm)
    {
        return [self serviceWithType:MSIDLegacyIDTokenType clientID:self.clientId realm:self.realm applicationIdentifier:nil target:nil appKey:self.appKey tokenType:self.tokenType requestedClaims:nil];
    }
    
    return nil;
}

- (NSData *)generic
{
    if (self.matchAnyCredentialType)
    {
        return nil;
    }

    NSString *clientId = self.queryClientId;

    if (!clientId)
    {
        return nil;
    }

    NSString *genericString = nil;

    if (self.credentialType == MSIDRefreshTokenType)
    {
        genericString = [self credentialIdWithType:self.credentialType clientId:clientId realm:nil applicationIdentifier:nil];
    }
    else if (self.realm)
    {
        genericString = [self credentialIdWithType:self.credentialType
                                          clientId:clientId
                                             realm:self.realm
                             applicationIdentifier:(self.credentialType == MSIDAccessTokenType || self.credentialType == MSIDAccessTokenWithAuthSchemeType) ? self.applicationIdentifier : nil];
    }

    return [genericString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSNumber *)type
{
    if (self.matchAnyCredentialType)
    {
        return nil;
    }

    return [self credentialTypeNumber:self.credentialType];
}

- (BOOL)exactMatch
{
    return self.service && self.account;
}

- (NSString *)queryClientId
{
    if ((self.clientId || self.familyId)
        && (self.clientIdMatchingOptions == MSIDExactStringMatch))
    {
        return self.familyId ? self.familyId : self.clientId;
    }

    return nil;
}

@end
