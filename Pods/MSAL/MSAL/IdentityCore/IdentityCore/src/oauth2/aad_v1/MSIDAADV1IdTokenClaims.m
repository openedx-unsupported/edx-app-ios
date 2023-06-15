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

#import "MSIDAADV1IdTokenClaims.h"
#import "MSIDHelpers.h"
#import "MSIDAADAuthority.h"

#define ID_TOKEN_UPN                @"upn"
#define ID_TOKEN_IDP                @"idp"
#define ID_TOKEN_OID                @"oid"
#define ID_TOKEN_TID                @"tid"
#define ID_TOKEN_UNIQUE_NAME        @"unique_name"
#define ID_TOKEN_ALT_SEC_ID         @"altsecid"

@implementation MSIDAADV1IdTokenClaims

MSID_JSON_ACCESSOR(ID_TOKEN_UPN, upn)
MSID_JSON_ACCESSOR(ID_TOKEN_IDP, identityProvider)
MSID_JSON_ACCESSOR(ID_TOKEN_OID, objectId)
MSID_JSON_ACCESSOR(ID_TOKEN_TID, tenantId)
MSID_JSON_ACCESSOR(ID_TOKEN_UNIQUE_NAME, uniqueName)

- (void)initDerivedProperties
{
    [super initDerivedProperties];

    // Set uniqueId
    NSString *uniqueId = self.objectId;

    if ([NSString msidIsStringNilOrBlank:uniqueId])
    {
        uniqueId = self.subject;
    }

    _uniqueId = [MSIDHelpers normalizeUserId:uniqueId];

    // Set userId (ADAL fallbacks)
    if (![NSString msidIsStringNilOrBlank:self.upn])
    {
        _userId = self.upn;
        _userIdDisplayable = YES;
    }
    else if (![NSString msidIsStringNilOrBlank:self.email])
    {
        _userId = self.email;
        _userIdDisplayable = YES;
    }
    else if (![NSString msidIsStringNilOrBlank:self.subject])
    {
        _userId = self.subject;
        _userIdDisplayable = NO;
    }
    else if (![NSString msidIsStringNilOrBlank:self.objectId])
    {
        _userId = self.objectId;
        _userIdDisplayable = NO;
    }
    else if (![NSString msidIsStringNilOrBlank:self.uniqueName])
    {
        _userId = self.uniqueName;
        _userIdDisplayable = YES;
    }
    else if (![NSString msidIsStringNilOrBlank:self.alternativeAccountId])
    {
        _userId = self.alternativeAccountId;
        _userIdDisplayable = NO;
    }

    _userId = [MSIDHelpers normalizeUserId:_userId];
    
    if (!self.issuer)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Issuer is not present in the provided AAD v1 id token claims");
        return;
    }
    
    NSError *issuerError = nil;
    _issuerAuthority = [[MSIDAADAuthority alloc] initWithURL:[NSURL URLWithString:self.issuer] rawTenant:nil context:nil error:&issuerError];
    
    if (!_issuerAuthority)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Failed to initialize issuer authority with error %@, %ld", issuerError.domain, (long)issuerError.code);
    }
}

- (NSString *)alternativeAccountId
{
    return [_json msidStringObjectForKey:ID_TOKEN_ALT_SEC_ID];
}

- (NSString *)realm
{
    return self.tenantId;
}

@end
