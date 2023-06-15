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

#import "MSIDIdTokenClaims.h"
#import "MSIDHelpers.h"
#import "MSIDAuthority+Internal.h"

#define ID_TOKEN_SUBJECT             @"sub"
#define ID_TOKEN_PERFERRED_USERNAME  @"preferred_username"
#define ID_TOKEN_NAME                @"name"
#define ID_TOKEN_GIVEN_NAME          @"given_name"
#define ID_TOKEN_FAMILY_NAME         @"family_name"
#define ID_TOKEN_MIDDLE_NAME         @"middle_name"
#define ID_TOKEN_EMAIL               @"email"
#define ID_TOKEN_ISSUER              @"iss"

@implementation MSIDIdTokenClaims

MSID_JSON_ACCESSOR(ID_TOKEN_SUBJECT, subject)
MSID_JSON_ACCESSOR(ID_TOKEN_PERFERRED_USERNAME, preferredUsername)
MSID_JSON_ACCESSOR(ID_TOKEN_NAME, name)
MSID_JSON_ACCESSOR(ID_TOKEN_GIVEN_NAME, givenName)
MSID_JSON_ACCESSOR(ID_TOKEN_FAMILY_NAME, familyName)
MSID_JSON_ACCESSOR(ID_TOKEN_MIDDLE_NAME, middleName)
MSID_JSON_ACCESSOR(ID_TOKEN_EMAIL, email)
MSID_JSON_ACCESSOR(ID_TOKEN_ISSUER, issuer)

- (instancetype)initWithRawIdToken:(NSString *)rawIdTokenString error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:rawIdTokenString])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Nil id_token passed", nil, nil, nil, nil, nil, YES);
        }

        return nil;
    }
    
    _rawIdToken = rawIdTokenString;
    
    NSArray* parts = [rawIdTokenString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    if (parts.count != 3)
    {
        // Log a warning, but still try to read the id token for backward compatibility...
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Id token is not a JWT token");
    }

    if (parts.count < 1)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Id token is invalid");

        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Server returned empty id token", nil, nil, nil, nil, nil, NO);
        }

        return nil;
    }

    NSMutableDictionary *allClaims = [NSMutableDictionary dictionary];

    for (NSString *part in parts)
    {
        NSData *decoded =  [[part msidBase64UrlDecode] dataUsingEncoding:NSUTF8StringEncoding];

        if (decoded && [decoded length])
        {
            NSError *jsonError = nil;
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:decoded options:0 error:&jsonError];

            if (jsonError)
            { 
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning
                                          , nil, @"Failed to deserialize part of the id_token %@", MSID_PII_LOG_MASKABLE(jsonError));

                if (error) *error = jsonError;
                return nil;
            }

            if (![jsonObject isKindOfClass:[NSDictionary class]])
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Invalid id token format");

                if (error)
                {
                    *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Server returned invalid id token", nil, nil, nil, nil, nil, YES);
                }

                return nil;
            }

            [allClaims addEntriesFromDictionary:jsonObject];
        }
    }

    if (![allClaims count])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Id token is invalid");

        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Server returned id token without any claims", nil, nil, nil, nil, nil, YES);
        }

        return nil;
    }

    if (!(self = [super initWithJSONDictionary:allClaims error:error]))
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Id token is invalid");
        return nil;
    }
    
    [self initDerivedProperties];
    return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError *__autoreleasing *)error
{
    self = [super initWithJSONDictionary:json error:error];

    if (self)
    {
        [self initDerivedProperties];
    }

    return self;
}

- (void)initDerivedProperties
{
    _uniqueId = [MSIDHelpers normalizeUserId:self.subject];
    _userId = [MSIDHelpers normalizeUserId:self.subject];
    _userIdDisplayable = NO;
    // TODO: change this to base Oauth2 authority once we support other IDPs
    _issuerAuthority = [[MSIDAuthority alloc] initWithURL:[NSURL URLWithString:self.issuer] context:nil error:nil];
}

- (NSString *)username
{
    return self.preferredUsername ? self.preferredUsername : self.userId;
}

- (NSString *)alternativeAccountId
{
    return nil;
}

- (NSString *)realm
{
    return nil;
}

@end
