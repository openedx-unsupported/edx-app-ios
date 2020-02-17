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

#import "MSIDCredentialType.h"

@implementation MSIDCredentialTypeHelpers

+ (NSString *)credentialTypeAsString:(MSIDCredentialType)type
{
    switch (type)
    {
        case MSIDAccessTokenType:
            return MSID_ACCESS_TOKEN_CACHE_TYPE;
            
        case MSIDRefreshTokenType:
            return MSID_REFRESH_TOKEN_CACHE_TYPE;
            
        case MSIDLegacySingleResourceTokenType:
            return MSID_LEGACY_TOKEN_CACHE_TYPE;
            
        case MSIDIDTokenType:
            return MSID_ID_TOKEN_CACHE_TYPE;
            
        case MSIDPrimaryRefreshTokenType:
            return MSID_PRT_TOKEN_CACHE_TYPE;
            
        case MSIDLegacyIDTokenType:
            return MSID_LEGACY_ID_TOKEN_CACHE_TYPE;
            
        default:
            return MSID_GENERAL_TOKEN_CACHE_TYPE;
    }
}

static NSDictionary *sCredentialTypes = nil;

+ (MSIDCredentialType)credentialTypeFromString:(NSString *)type
{
    static dispatch_once_t sCredentialTypesOnce;
    
    dispatch_once(&sCredentialTypesOnce, ^{
        
        sCredentialTypes = @{[MSID_ACCESS_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDAccessTokenType),
                             [MSID_REFRESH_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDRefreshTokenType),
                             [MSID_LEGACY_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDLegacySingleResourceTokenType),
                             [MSID_ID_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDIDTokenType),
                             [MSID_PRT_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDPrimaryRefreshTokenType),
                             [MSID_LEGACY_ID_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDLegacyIDTokenType),
                             [MSID_GENERAL_TOKEN_CACHE_TYPE lowercaseString]: @(MSIDCredentialTypeOther),
                             };
    });
    
    NSNumber *credentialType = sCredentialTypes[type.lowercaseString];
    return credentialType != nil ? [credentialType integerValue] : MSIDCredentialTypeOther;
}

+ (MSIDCredentialType)credentialTypeWithRefreshToken:(NSString *)refreshToken
                                         accessToken:(NSString *)accessToken
{
    BOOL rtPresent = ![NSString msidIsStringNilOrBlank:refreshToken];
    BOOL atPresent = ![NSString msidIsStringNilOrBlank:accessToken];
    
    if (rtPresent && atPresent)
    {
        return MSIDLegacySingleResourceTokenType;
    }
    else if (rtPresent)
    {
        return MSIDRefreshTokenType;
    }
    else if (atPresent)
    {
        return MSIDAccessTokenType;
    }
    
    return MSIDCredentialTypeOther;
}

@end
