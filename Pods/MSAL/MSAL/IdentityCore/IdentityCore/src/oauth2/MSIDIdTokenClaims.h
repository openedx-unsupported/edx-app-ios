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

#import "MSIDJsonObject.h"

@class MSIDAuthority;

@interface MSIDIdTokenClaims : MSIDJsonObject
{
    NSString *_uniqueId;
    NSString *_userId;
    BOOL _userIdDisplayable;
    MSIDAuthority *_issuerAuthority;
}

// Default properties
// REQUIRED. Subject Identifier. A locally unique and never reassigned identifier within the Issuer for the End-User, which is intended to be consumed by the Client, e.g., 24400320 or AItOawmwtWwcT0k51BayewNvutrJUqsvl6qs7A4. It MUST NOT exceed 255 ASCII characters in length. The sub value is a case sensitive string.
@property (readonly) NSString *subject;
// REQUIRED. Issuer Identifier for the Issuer of the response. The iss value is a case sensitive URL using the https scheme that contains scheme, host, and optionally, port number and path components and no query or fragment components.
@property (readonly) NSString *issuer;
// Shorthand name by which the End-User wishes to be referred to at the RP, such as janedoe or j.doe. This value MAY be any valid JSON string including special characters such as @, /, or whitespace. The RP MUST NOT rely upon this value being unique.
@property (readonly) NSString *preferredUsername;
@property (readonly) NSString *name;
@property (readonly) NSString *givenName;
@property (readonly) NSString *middleName;
@property (readonly) NSString *familyName;

// End-User's preferred e-mail address. Its value MUST conform to the RFC 5322 [RFC5322] addr-spec syntax. The RP MUST NOT rely upon this value being unique.
@property (readonly) NSString *email;

// Derived properties
@property (atomic, readonly) NSString *uniqueId;
@property (atomic, readonly) NSString *userId;
@property (atomic, readonly) BOOL userIdDisplayable;
@property (atomic, readonly) NSString *alternativeAccountId;
@property (atomic, readonly) MSIDAuthority *issuerAuthority;

// Convinience properties
@property (atomic, readonly) NSString *rawIdToken;
@property (readonly) NSString *realm;

- (instancetype)initWithRawIdToken:(NSString *)rawIdTokenString error:(NSError * __autoreleasing *)error;
- (NSString *)username;
- (void)initDerivedProperties;

@end
