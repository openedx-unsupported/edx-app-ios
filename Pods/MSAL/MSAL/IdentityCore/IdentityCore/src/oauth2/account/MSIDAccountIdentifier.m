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

#import "MSIDAccountIdentifier.h"
#import "MSIDClientInfo.h"
#import "MSIDMaskedHashableLogParameter.h"
#import "MSIDMaskedUsernameLogParameter.h"

@interface MSIDAccountIdentifier()

@property (nonatomic, readwrite) MSIDMaskedHashableLogParameter *maskedHomeAccountId;
@property (nonatomic, readwrite) MSIDMaskedUsernameLogParameter *maskedDisplayableId;

@end

@implementation MSIDAccountIdentifier

- (NSString *)description
{
    return [NSString stringWithFormat:@"MSIDAccountIdentifier displayableId: %@, homeAccountId: %@", self.displayableId, self.homeAccountId];
}

#pragma mark - Init

- (instancetype)initWithDisplayableId:(NSString *)legacyAccountId
                             clientInfo:(MSIDClientInfo *)clientInfo
{
    return [self initWithDisplayableId:legacyAccountId
                         homeAccountId:clientInfo.accountIdentifier];
}

- (instancetype)initWithDisplayableId:(NSString *)legacyAccountId
                          homeAccountId:(NSString *)homeAccountId
{
    if (!(self = [self init]))
    {
        return nil;
    }

    _displayableId = legacyAccountId;
    _homeAccountId = homeAccountId;
    _maskedHomeAccountId = MSID_PII_LOG_TRACKABLE(_homeAccountId);
    _maskedDisplayableId = MSID_PII_LOG_EMAIL(_displayableId);
    _legacyAccountIdentifierType = MSIDLegacyIdentifierTypeRequiredDisplayableId;

    NSArray *accountComponents = [homeAccountId componentsSeparatedByString:@"."];

    if ([accountComponents count] == 2)
    {
        _uid = accountComponents[0];
        _utid = accountComponents[1];
    }

    return self;
}

+ (NSString *)legacyAccountIdentifierTypeAsString:(MSIDLegacyAccountIdentifierType)type
{
    switch (type) {
        case MSIDLegacyIdentifierTypeOptionalDisplayableId:
            return @"OptionalDisplayableId";
        case MSIDLegacyIdentifierTypeRequiredDisplayableId:
            return @"RequiredDisplayableId";
        case MSIDLegacyIdentifierTypeUniqueNonDisplayableId:
            return @"UniqueId";

        default:
            return @"";
    }
}

+ (MSIDLegacyAccountIdentifierType)legacyAccountIdentifierTypeFromString:(NSString *)typeString
{
    if ([typeString isEqualToString:@"UniqueId"])               return MSIDLegacyIdentifierTypeUniqueNonDisplayableId;
    if ([typeString isEqualToString:@"RequiredDisplayableId"])  return MSIDLegacyIdentifierTypeRequiredDisplayableId;
    if ([typeString isEqualToString:@"OptionalDisplayableId"])  return MSIDLegacyIdentifierTypeOptionalDisplayableId;
        
    return MSIDLegacyIdentifierTypeOptionalDisplayableId; // default for broker.
}

+ (NSString *)homeAccountIdentifierFromUid:(NSString *)uid utid:(NSString *)utid
{
    if (uid && utid)
    {
        return [NSString stringWithFormat:@"%@.%@", uid, utid];
    }
    else return nil;
}

#pragma mark - Copy

- (instancetype)copyWithZone:(NSZone *)zone
{
    MSIDAccountIdentifier *account = [[MSIDAccountIdentifier allocWithZone:zone] initWithDisplayableId:[self.displayableId copyWithZone:zone] homeAccountId:[self.homeAccountId copyWithZone:zone]];
    account.legacyAccountIdentifierType = _legacyAccountIdentifierType;
    account.localAccountId = [self.localAccountId copyWithZone:zone];
    account.uid = [self.uid copyWithZone:zone];
    account.utid = [self.utid copyWithZone:zone];
    return account;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:MSIDAccountIdentifier.class])
    {
        return NO;
    }

    return [self isEqualToItem:(MSIDAccountIdentifier *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.homeAccountId.hash;
    hash = hash * 31 + self.displayableId.hash;
    hash = hash * 31 + self.localAccountId.hash;
    hash = hash * 31 + self.legacyAccountIdentifierType;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDAccountIdentifier *)account
{
    if (!account)
    {
        return NO;
    }

    BOOL result = YES;
    result &= (!self.homeAccountId && !account.homeAccountId) || [self.homeAccountId isEqualToString:account.homeAccountId];
    result &= (!self.displayableId && !account.displayableId) || [self.displayableId isEqualToString:account.displayableId];
    result &= (!self.localAccountId && !account.localAccountId) || [self.localAccountId isEqualToString:account.localAccountId];
    result &= self.legacyAccountIdentifierType == account.legacyAccountIdentifierType;
    return result;
}

@end
