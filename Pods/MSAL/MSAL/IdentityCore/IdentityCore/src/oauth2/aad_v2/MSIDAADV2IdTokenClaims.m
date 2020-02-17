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

#import "MSIDAADV2IdTokenClaims.h"
#import "MSIDHelpers.h"
#import "MSIDAADAuthority.h"

#define ID_TOKEN_ISSUER              @"iss"
#define ID_TOKEN_OBJECT_ID           @"oid"
#define ID_TOKEN_TENANT_ID           @"tid"
#define ID_TOKEN_VERSION             @"ver"
#define ID_TOKEN_HOME_OBJECT_ID      @"home_oid"
#define ID_TOKEN_ALT_SEC_ID          @"altsecid"

@implementation MSIDAADV2IdTokenClaims

MSID_JSON_ACCESSOR(ID_TOKEN_ISSUER, issuer)
MSID_JSON_ACCESSOR(ID_TOKEN_OBJECT_ID, objectId)
MSID_JSON_ACCESSOR(ID_TOKEN_TENANT_ID, tenantId)
MSID_JSON_ACCESSOR(ID_TOKEN_VERSION, version)
MSID_JSON_ACCESSOR(ID_TOKEN_HOME_OBJECT_ID, homeObjectId)

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

    // Set userId
    NSString *userId = self.preferredUsername;

    if ([NSString msidIsStringNilOrBlank:userId])
    {
        userId = self.subject;
    }

    _userId = [MSIDHelpers normalizeUserId:userId];
    _userIdDisplayable = YES;
    
    if (!self.issuer)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Issuer is not present in the provided AAD v2 id token claims");
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
