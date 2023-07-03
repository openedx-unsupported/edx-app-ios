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

#import "MSIDAppMetadataCacheKey.h"
#import "NSString+MSIDExtensions.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDGeneralCacheItemType.h"
#import "NSURL+MSIDExtensions.h"

static NSString *keyDelimiter = @"-";
static NSInteger kGeneralTypePrefix = 3000;

@implementation MSIDAppMetadataCacheKey

#pragma mark - Helpers

- (NSString *)serviceWithType:(MSIDGeneralCacheItemType)type clientId:(NSString *)clientId
{
    clientId = clientId.msidTrimmedString.lowercaseString;
    NSString *service = [NSString stringWithFormat:@"%@%@%@",
                         [MSIDGeneralCacheItemTypeHelpers generalTypeAsString:type],
                         keyDelimiter,
                         clientId];
    return service;
}

- (NSNumber *)generalTypeNumber:(MSIDGeneralCacheItemType)generalType
{
    return @(kGeneralTypePrefix + generalType);
}

#pragma mark - Public

- (instancetype)initWithClientId:(NSString *)clientId
                     environment:(NSString *)environment
                        familyId:(NSString *)familyId
                     generalType:(MSIDGeneralCacheItemType)type
{
    self = [super init];
    
    if (self)
    {
        _clientId = clientId;
        _environment = environment;
        _generalType = type;
        _familyId = familyId;
    }
    
    return self;
}

- (NSData *)generic
{
    return [self.familyId dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSNumber *)type
{
    return [self generalTypeNumber:self.generalType];
}

- (NSString *)account
{
    return self.environment;
}

- (NSString *)service
{
    return [self serviceWithType:self.generalType clientId:self.clientId];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAppMetadataCacheKey *item = [[self.class allocWithZone:zone] init];
    item->_clientId = [_clientId copyWithZone:zone];
    item->_environment = [_environment copyWithZone:zone];
    item->_generalType = _generalType;
    item->_familyId = [_familyId copyWithZone:zone];
    return item;
}

@end
