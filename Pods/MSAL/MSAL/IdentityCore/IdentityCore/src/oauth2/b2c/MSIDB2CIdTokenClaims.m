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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDB2CIdTokenClaims.h"
#import "MSIDHelpers.h"
#import "MSIDB2CAuthority.h"

@implementation MSIDB2CIdTokenClaims

MSID_JSON_ACCESSOR(@"tfp", tfp)

- (void)initDerivedProperties
{
    [super initDerivedProperties];

    // Set userId
    NSString *userId = self.preferredUsername;

    if ([NSString msidIsStringNilOrBlank:userId])
    {
        userId = self.subject;
        _userIdDisplayable = NO;
    }
    else
    {
        _userIdDisplayable = YES;
    }

    _userId = [MSIDHelpers normalizeUserId:userId];
    
    if (!self.issuer)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Issuer is not present in the provided B2C id token claims");
        return;
    }
    
    NSError *issuerError = nil;
    _issuerAuthority = [[MSIDB2CAuthority alloc] initWithURL:[NSURL URLWithString:self.issuer] validateFormat:NO context:nil error:&issuerError];
    
    if (!_issuerAuthority)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Failed to initialize issuer authority with error %@, %ld", issuerError.domain, (long)issuerError.code);
    }
}

- (NSString *)alternativeAccountId
{
    return nil;
}

- (NSString *)realm
{
    return self.tenantId;
}

@end

#endif
