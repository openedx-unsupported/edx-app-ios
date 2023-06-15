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

#import "MSIDIndividualClaimRequest.h"
#import "MSIDIndividualClaimRequestAdditionalInfo.h"

@implementation MSIDIndividualClaimRequest

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
    }
    return self;
}

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(name=%@, additional info=%@)", self.name, self.additionalInfo];
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super init];
    if (self)
    {
        if ([json allKeys].count != 1)
        {
            if (error) *error = MSIDCreateError(MSIDErrorDomain,
                                                MSIDErrorInvalidDeveloperParameter,
                                                @"Invalid json.",
                                                nil, nil, nil, nil, nil, NO);
            
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to init MSIDIndividualClaimRequest with json: json is invalid.");
            return nil;
        }
        
        NSString *claimName = [json allKeys].firstObject;
        
        if (![claimName isKindOfClass:NSString.class])
        {
            if (error) *error = MSIDCreateError(MSIDErrorDomain,
                                                MSIDErrorInvalidDeveloperParameter,
                                                @"Claim name is not a string.",
                                                nil, nil, nil, nil, nil, NO);
            
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to init MSIDIndividualClaimRequest with json: claim name is not a string.");
            return nil;
        }
        
        if (![json[claimName] isKindOfClass:NSNull.class])
        {
            if (![json msidAssertTypeIsOneOf:@[NSDictionary.class] ofKey:claimName required:YES context:nil errorCode:MSIDErrorInvalidDeveloperParameter error:error]) return nil;
            
            NSError *localError;
            __auto_type additinalInfo = [[MSIDIndividualClaimRequestAdditionalInfo alloc] initWithJSONDictionary:json[claimName] error:&localError];
            if (localError)
            {
                if (error) *error = localError;
                return nil;
            }
            
            _additionalInfo = additinalInfo;
        }
        
        _name = claimName;
    }
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *claimJson = [NSMutableDictionary new];
    
    if (!self.name)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"name property of individual claim request is nil.");
        return nil;
    }
    
    if (self.additionalInfo)
    {
        NSDictionary *additionalInfoJson = [self.additionalInfo jsonDictionary];
        if (!additionalInfoJson) return nil;
        
        claimJson[self.name] = additionalInfoJson;
    }
    else
    {
        claimJson[self.name] = [NSNull new];
    }
    
    return claimJson;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDIndividualClaimRequest.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDIndividualClaimRequest *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.name.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDIndividualClaimRequest *)request
{
    if (!request) return NO;
    
    BOOL result = YES;
    result &= (!self.name && !request.name) || [self.name isEqualToString:request.name];
    return result;
}

@end
