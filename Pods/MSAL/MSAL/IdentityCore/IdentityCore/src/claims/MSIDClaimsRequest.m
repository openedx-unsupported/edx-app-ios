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

#import "MSIDClaimsRequest.h"
#import "MSIDIndividualClaimRequest.h"
#import "MSIDIndividualClaimRequestAdditionalInfo.h"

@interface MSIDClaimsRequest()

@property (nonatomic) NSMutableDictionary *claimsRequestsDict;

@end

@implementation MSIDClaimsRequest

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(%@)", [self.claimsRequestsDict description]];
}

- (NSMutableDictionary *)claimsRequestsDict
{
    if (!_claimsRequestsDict) _claimsRequestsDict = [NSMutableDictionary new];
    
    return _claimsRequestsDict;
}

- (NSUInteger)count
{
    return self.claimsRequestsDict.count;
}

- (BOOL)hasClaims
{
    return self.claimsRequestsDict.count != 0;
}

- (BOOL)requestClaim:(MSIDIndividualClaimRequest *)request
           forTarget:(MSIDClaimsRequestTarget)target
               error:(NSError **)error
{
    if (!request)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidDeveloperParameter,
                                     @"Claim request is nil.",
                                     nil, nil, nil, nil, nil, NO);
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to request claim: claim request is nil.");
        return NO;
    }
    
    if (target == MSIDClaimsRequestTargetInvalid)
    {
        NSAssert(NO, @"Target is invalid.");
        return NO;
    }
    
    __auto_type key = [[NSNumber alloc] initWithLong:target];
    
    NSMutableSet *requests = self.claimsRequestsDict[key] ?: [NSMutableSet new];
    
    if ([requests containsObject:request]) [requests removeObject:request];
    
    [requests addObject:request];
    
    self.claimsRequestsDict[key] = requests;
    
    return YES;
}

- (NSArray<MSIDIndividualClaimRequest *> *)claimsRequestsForTarget:(MSIDClaimsRequestTarget)target
{
    if (!self.claimsRequestsDict) return nil;
    
    __auto_type key = [[NSNumber alloc] initWithLong:target];
    NSArray *requests = [self.claimsRequestsDict[key] allObjects] ?: [NSArray new];
    
    return requests;
}

- (BOOL)removeClaimRequestWithName:(NSString *)name
                            target:(MSIDClaimsRequestTarget)target
                             error:(NSError **)error
{
    if (!name)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidDeveloperParameter,
                                     @"Name is nil.",
                                     nil, nil, nil, nil, nil, NO);
        }
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to remove claim: name is nil.");
        
        return NO;
    }
    
    __auto_type key = [[NSNumber alloc] initWithLong:target];
    if (!self.claimsRequestsDict[key]) return NO;
    
    NSMutableSet *requests = self.claimsRequestsDict[key];
    
    MSIDIndividualClaimRequest *tmpRequest = [[MSIDIndividualClaimRequest alloc] initWithName:name];
    if (![requests containsObject:tmpRequest]) return NO;
        
    [requests removeObject:tmpRequest];
    
    self.claimsRequestsDict[key] = requests;
    
    return YES;
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone
{
    MSIDClaimsRequest *item = [MSIDClaimsRequest new];
    item->_claimsRequestsDict = [_claimsRequestsDict mutableCopy];
    return item;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super init];
    if (self)
    {
        for (NSString *key in [json allKeys])
        {
            NSError *localError;
            __auto_type target = [self targetFromString:key error:&localError];
            if (localError)
            {
                if (error) *error = localError;
                return nil;
            }
            
            if (![json msidAssertTypeIsOneOf:@[NSDictionary.class] ofKey:key required:YES context:nil errorCode:MSIDErrorInvalidDeveloperParameter error:error]) return nil;
            
            NSDictionary *claimRequestsJson = json[key];
            for (NSString *innerKey in [claimRequestsJson allKeys])
            {
                NSDictionary *claimRequestJson = @{innerKey: claimRequestsJson[innerKey]};
                __auto_type claimRequest = [[MSIDIndividualClaimRequest alloc] initWithJSONDictionary:claimRequestJson error:&localError];
                
                if (localError)
                {
                    if (error) *error = localError;
                    return nil;
                }
                
                BOOL result = [self requestClaim:claimRequest forTarget:target error:error];
                if (!result) return nil;
            }
        }
    }
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *claimsRequestJson = [NSMutableDictionary new];
    
    for (NSNumber *target in self.claimsRequestsDict.allKeys)
    {
        NSArray *requests = self.claimsRequestsDict[target];
        if (requests.count == 0) continue;
        
        __auto_type requestsJson = [NSMutableDictionary new];
        
        for (MSIDIndividualClaimRequest *request in requests)
        {
            NSDictionary *requestJson = [request jsonDictionary];
            if (!requestJson) return nil;
            
            [requestsJson addEntriesFromDictionary:requestJson];
        }
        
        NSString *targetString = [self stringFromTarget:[target integerValue]];
        claimsRequestJson[targetString] = requestsJson;
    }
    
    return claimsRequestJson;
}

#pragma mark - Private

- (MSIDClaimsRequestTarget)targetFromString:(NSString *)string error:(NSError **)error
{
    if ([string isEqualToString:MSID_OAUTH2_ID_TOKEN]) return MSIDClaimsRequestTargetIdToken;
    if ([string isEqualToString:MSID_OAUTH2_ACCESS_TOKEN]) return MSIDClaimsRequestTargetAccessToken;
    
    if (error)
    {
        __auto_type message = [NSString stringWithFormat:@"Invalid claims target: %@", string];
        *error = MSIDCreateError(MSIDErrorDomain,
                                 MSIDErrorInvalidDeveloperParameter,
                                 message,
                                 nil, nil, nil, nil, nil, NO);
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Invalid claims target: %@", string);
    
    return MSIDClaimsRequestTargetInvalid;
}

- (NSString *)stringFromTarget:(MSIDClaimsRequestTarget)target
{
    if (target == MSIDClaimsRequestTargetIdToken) return MSID_OAUTH2_ID_TOKEN;
    if (target == MSIDClaimsRequestTargetAccessToken) return MSID_OAUTH2_ACCESS_TOKEN;
    
    NSAssert(NO, @"There is no string representation for provided target.");
    return nil;
}

@end
