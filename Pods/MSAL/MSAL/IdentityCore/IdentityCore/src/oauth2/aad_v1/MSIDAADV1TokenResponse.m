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

#import "MSIDAADV1TokenResponse.h"
#import "MSIDAADV1IdTokenClaims.h"
#import "MSIDTokenResponse+Internal.h"

@implementation MSIDAADV1TokenResponse

MSID_JSON_ACCESSOR(MSID_OAUTH2_RESOURCE, resource)

- (BOOL)initIdToken:(NSError *__autoreleasing *)error
{
    if (![NSString msidIsStringNilOrBlank:self.idToken])
    {
        self.idTokenObj = [[MSIDAADV1IdTokenClaims alloc] initWithRawIdToken:self.idToken error:error];
        return self.idTokenObj != nil;
    }
    
    return YES;
}

- (BOOL)isMultiResource
{
    // TODO: this was brought over from ADAL, find and add a link to documentation describing this behavior
    return ![NSString msidIsStringNilOrBlank:self.resource]
            && ![NSString msidIsStringNilOrBlank:self.refreshToken];
}

- (NSString *)target
{
    return self.resource;
}

- (MSIDAccountType)accountType
{
    return MSIDAccountTypeAADV1;
}

@end
