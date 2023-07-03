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

#import "MSIDJsonSerializable.h"
#import "MSIDKeyGenerator.h"

typedef NS_ENUM(NSInteger, MSIDAccountMetadataState)
{
    MSIDAccountMetadataStateUnknown = 0,
    MSIDAccountMetadataStateSignedIn,
    MSIDAccountMetadataStateSignedOut
};

@interface MSIDAccountMetadata : NSObject <MSIDJsonSerializable, NSCopying>

@property (nonatomic, readonly) NSString *homeAccountId;
@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSDictionary *auhtorityMap;

@property (nonatomic, readonly) MSIDAccountMetadataState signInState;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithHomeAccountId:(NSString *)homeAccountId
                             clientId:(NSString *)clientId;

// Authority map caching
- (BOOL)setCachedURL:(NSURL *)cachedURL
       forRequestURL:(NSURL *)requestURL
       instanceAware:(BOOL)instanceAware
               error:(NSError **)error;
- (NSURL *)cachedURL:(NSURL *)requestURL instanceAware:(BOOL)instanceAware;

// Update sign in state
- (void)updateSignInState:(MSIDAccountMetadataState)state;

@end
