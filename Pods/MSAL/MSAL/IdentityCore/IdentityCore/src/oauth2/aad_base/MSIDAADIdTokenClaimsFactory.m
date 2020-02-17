//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDAADV2IdTokenClaims.h"
#import "MSIDAADV1IdTokenClaims.h"

@implementation MSIDAADIdTokenClaimsFactory

+ (MSIDIdTokenClaims *)claimsFromRawIdToken:(NSString *)rawIdTokenString error:(NSError **)error
{
    MSIDIdTokenClaims *claims = [[MSIDIdTokenClaims alloc] initWithRawIdToken:rawIdTokenString error:error];

    NSDictionary *allClaims = [claims jsonDictionary];
    NSString *idTokenVersionClaim = allClaims[@"ver"];
    CGFloat idTokenVersion = [idTokenVersionClaim floatValue];

    // If version claim is returned, determine ID token version based on the version claim
    if (![NSString msidIsStringNilOrBlank:idTokenVersionClaim])
    {
        if (idTokenVersion == 1.0f)
        {
            return [[MSIDAADV1IdTokenClaims alloc] initWithJSONDictionary:allClaims error:error];
        }
        else if (idTokenVersion == 2.0f)
        {
            return [[MSIDAADV2IdTokenClaims alloc] initWithJSONDictionary:allClaims error:error];
        }
    }

    // If no version claim is returned, or it's unsupported version, check if UPN or unique_name claims are present
    // If UPN/unique_name is present, return AAD v1 id token.
    // Return base OIDC token in all other cases
    // Note, that we shouldn't be checking for upn claim only and deciding v1 vs v2, because if v2 adds upn claim one day, this logic will break
    // However, AAD cannot stop returning ver 2.0 claim for AAD v2 or upn/unique_name for AAD v1 because that would be a breaking change, so we can rely on those
    NSString *idTokenUPNClaim = allClaims[@"upn"];
    NSString *idTokenUniqueNameClaim = allClaims[@"unique_name"];

    if (![NSString msidIsStringNilOrBlank:idTokenUPNClaim]
        || ![NSString msidIsStringNilOrBlank:idTokenUniqueNameClaim])
    {
        return [[MSIDAADV1IdTokenClaims alloc] initWithJSONDictionary:allClaims error:error];
    }

    return claims;
}

@end
