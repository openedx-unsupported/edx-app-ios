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
#import "MSIDJsonSerializableTypes.h"
#import "MSIDJsonSerializableFactory.h"

@implementation MSIDAADV1TokenResponse

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:MSID_JSON_TYPE_AADV1_TOKEN_RESPONSE];
    [MSIDJsonSerializableFactory mapJSONKey:MSID_PROVIDER_TYPE_JSON_KEY keyValue:MSID_JSON_TYPE_PROVIDER_AADV1 kindOfClass:MSIDTokenResponse.class toClassType:MSID_JSON_TYPE_AADV1_TOKEN_RESPONSE];
}

- (MSIDIdTokenClaims *)tokenClaimsFromRawIdToken:(NSString *)rawIdToken error:(NSError **)error
{
    return [[MSIDAADV1IdTokenClaims alloc] initWithRawIdToken:rawIdToken error:error];
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

+ (MSIDProviderType)providerType
{
    return MSIDProviderTypeAADV1;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    if (self)
    {
        _resource = [json msidStringObjectForKey:MSID_OAUTH2_RESOURCE];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableDeepCopy];
    json[MSID_OAUTH2_RESOURCE] = self.resource;
    
    return json;
}

@end
