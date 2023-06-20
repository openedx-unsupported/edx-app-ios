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

#import "MSIDBrokerOperationTokenResponse.h"
#import "MSIDAADV2TokenResponse.h"
#import "MSIDDefaultTokenResponseValidator.h"
#import "MSIDAADV2Oauth2Factory.h"
#import "MSIDAccessToken.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDAADV2TokenResponse.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializer.h"

NSString *const MSID_BROKER_ADDITIONAL_TOKEN_RESPONSE_JSON_KEY = @"additional_token_reponse";

@implementation MSIDBrokerOperationTokenResponse

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.responseType];
}

+ (NSString *)responseType
{
    return MSID_JSON_TYPE_BROKER_OPERATION_TOKEN_RESPONSE;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        if (self.success)
        {
            _authority = (MSIDAuthority *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_PROVIDER_TYPE_JSON_KEY assertKindOfClass:MSIDAuthority.class error:error];
            if (!_authority) return nil;
        }
        
        _tokenResponse = (MSIDTokenResponse *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_PROVIDER_TYPE_JSON_KEY assertKindOfClass:MSIDTokenResponse.class error:error];
        if (!_tokenResponse) return nil;
        
        if (![json msidAssertType:NSString.class ofKey:MSID_BROKER_ADDITIONAL_TOKEN_RESPONSE_JSON_KEY required:NO error:error]) return nil;
        NSString *tokenResponseJsonString = json[MSID_BROKER_ADDITIONAL_TOKEN_RESPONSE_JSON_KEY];
        if (tokenResponseJsonString)
        {
            NSDictionary *tokenResponseJson = (NSDictionary *)[[MSIDJsonSerializer new] fromJsonString:tokenResponseJsonString ofType:NSDictionary.class context:nil error:nil];
            _additionalTokenResponse = (MSIDTokenResponse *)[MSIDJsonSerializableFactory createFromJSONDictionary:tokenResponseJson classTypeJSONKey:MSID_PROVIDER_TYPE_JSON_KEY assertKindOfClass:MSIDTokenResponse.class error:nil];
        }
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    if (self.success)
    {
        NSDictionary *authorityJson = [self.authority jsonDictionary];
        if (!authorityJson)
        {
            MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, authority json is nil.", self.class);
            return nil;
        }
        [json addEntriesFromDictionary:authorityJson];
    }
    
    if (self.additionalTokenResponse)
    {
        NSDictionary *tokenResponseJson = [self.additionalTokenResponse jsonDictionary];
        if (tokenResponseJson)
        {
            
            json[MSID_BROKER_ADDITIONAL_TOKEN_RESPONSE_JSON_KEY] = [tokenResponseJson msidJSONSerializeWithContext:nil];
        }
        else
        {
            MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for additional token response.");
        }
    }
    
    NSDictionary *responseJson = [_tokenResponse jsonDictionary];
    if (!responseJson)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, tokenResponse json is nil.", self.class);
        return nil;
    }
    
    [json addEntriesFromDictionary:responseJson];
    
    return json;
}

@end
