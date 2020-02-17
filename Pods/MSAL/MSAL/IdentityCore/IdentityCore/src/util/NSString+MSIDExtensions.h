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

#import <Foundation/Foundation.h>

@interface NSString (MSIDExtensions)
/*!
 =============================================================================
 Encoding/Decoding and other string calculations/manipulations
 =============================================================================
 */
/*! Encodes string to the Base64 encoding. */
- (NSString *)msidBase64UrlEncode;
/*! Decodes string from the Base64 encoding. */
- (NSString *)msidBase64UrlDecode;

/*! Returns YES if the string is nil, or contains only white space */
+ (BOOL)msidIsStringNilOrBlank:(NSString *)string;

/*! Returns the same string, but without the leading and trailing whitespace */
- (NSString *)msidTrimmedString;

/*! Returns the same string, but lowercased and without the leading and trailing whitespace */
- (NSString *)msidNormalizedString;

/*! Decodes a application/x-www-form-urlencoded string.
 See https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4 for more details. */
- (NSString *)msidWWWFormURLDecode;

/*! URL decode (Percentage decode), in accordance to
 https://tools.ietf.org/html/rfc3986 */
- (NSString *)msidURLDecode;

/*! URL encode (Percentage encode), in accordance to
 https://tools.ietf.org/html/rfc3986 */
- (NSString *)msidURLEncode;

/*! Encodes the string to be application/x-www-form-urlencoded.
 See https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4 for more details.  */
- (NSString *)msidWWWFormURLEncode;

/*! Calculates a hash of the passed string. Useful for logging tokens, where we do not log
 the actual contents, but still want to log something that can be correlated. */
- (NSString *)msidTokenHash;

/*! Check if current string is included in the array - case insensitive */
- (BOOL)msidIsEquivalentWithAnyAlias:(NSArray<NSString *> *)aliases;

/*!
 =============================================================================
 String constructors
 =============================================================================
 */
/*! Generate a URL-safe string of random data */
+ (NSString *)msidRandomUrlSafeStringOfByteSize:(NSUInteger)size;

/*! Generate a hex string from data */
+ (NSString *)msidHexStringFromData:(NSData *)data;

/*! Generate a base64 url-encoded string from data */
+ (NSString *)msidBase64UrlEncodedStringFromData:(NSData *)data;

/*! Generate a percentage encoded string from dictionary
 Key and value are separated by '=' and key-value tuples are separated by &.
 */
+ (NSString *)msidURLEncodedStringFromDictionary:(NSDictionary *)dict;

/*! Generate a www-form-urlencoded string from dictionary
 Key and value are separated by '=' and key-value tuples are separated by &.
 Non-alphanumeric characters are percent encoded for both keys and values.
 See https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4 for more details.
 */
+ (NSString *)msidWWWFormURLEncodedStringFromDictionary:(NSDictionary *)dict;

/*!
 =============================================================================
 Convenience methods
 =============================================================================
 */
/*! Convenience method to convert string to NSOrderedSet */
+ (NSString *)msidStringFromOrderedSet:(NSOrderedSet *)set;

/*! Convenience method to convert string to scope set */
- (NSOrderedSet<NSString *> *)msidScopeSet;

/*! Convenience method to convert json string to a dictionary.
 Returns nil if it is not a json string. */
- (NSDictionary *)msidJson;

/*! Convert resource to scope */
+ (NSString *)msidScopeFromResource:(NSString *)resource;

/* Use this method to log sensitive information like password, access token etc. */
- (NSString *)msidSecretLoggingHash;

@end
