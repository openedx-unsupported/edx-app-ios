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

@class MSIDClientInfo;
@class MSIDMaskedHashableLogParameter;
@class MSIDMaskedUsernameLogParameter;

typedef NS_ENUM(NSInteger, MSIDLegacyAccountIdentifierType)
{
    MSIDLegacyIdentifierTypeOptionalDisplayableId = 0,
    MSIDLegacyIdentifierTypeRequiredDisplayableId,
    MSIDLegacyIdentifierTypeUniqueNonDisplayableId
};

@interface MSIDAccountIdentifier : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *homeAccountId;
@property (nonatomic, readonly) NSString *displayableId;
@property (nonatomic, readwrite) NSString *localAccountId;
@property (nonatomic, readwrite) MSIDLegacyAccountIdentifierType legacyAccountIdentifierType;
@property (nonatomic, readwrite) NSString *uid;
@property (nonatomic, readwrite) NSString *utid;
// Logging
@property (nonatomic, readonly) MSIDMaskedHashableLogParameter *maskedHomeAccountId;
@property (nonatomic, readonly) MSIDMaskedUsernameLogParameter *maskedDisplayableId;

- (instancetype)initWithDisplayableId:(NSString *)legacyAccountId
                        clientInfo:(MSIDClientInfo *)clientInfo;

- (instancetype)initWithDisplayableId:(NSString *)legacyAccountId
                          homeAccountId:(NSString *)homeAccountId;

+ (NSString *)legacyAccountIdentifierTypeAsString:(MSIDLegacyAccountIdentifierType)type;
+ (MSIDLegacyAccountIdentifierType)legacyAccountIdentifierTypeFromString:(NSString *)typeString;
+ (NSString *)homeAccountIdentifierFromUid:(NSString *)uid utid:(NSString *)utid;

@end
