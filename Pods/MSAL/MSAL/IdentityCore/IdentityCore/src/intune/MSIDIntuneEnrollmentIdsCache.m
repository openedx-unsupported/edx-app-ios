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

#import "MSIDIntuneEnrollmentIdsCache.h"
#import "MSIDIntuneInMemoryCacheDataSource.h"

NSString *const MSID_INTUNE_ENROLLMENT_ID_ARRAY = @"enrollment_ids";
NSString *const MSID_INTUNE_USER_ID = @"user_id";
NSString *const MSID_INTUNE_ENROLL_ID = @"enrollment_id";
NSString *const MSID_INTUNE_TID = @"tid";
NSString *const MSID_INTUNE_OID = @"oid";
NSString *const MSID_INTUNE_HOME_ACCOUNT_ID = @"home_account_id";

static MSIDIntuneEnrollmentIdsCache *s_sharedCache;

@interface MSIDIntuneEnrollmentIdsCache()

@property (nonatomic) id<MSIDIntuneCacheDataSource> dataSource;

@end

@implementation MSIDIntuneEnrollmentIdsCache

- (instancetype)initWithDataSource:(id<MSIDIntuneCacheDataSource>)dataSource
{
    self = [super init];
    if (self)
    {
        _dataSource = dataSource;
    }
    return self;
}

+ (void)setSharedCache:(MSIDIntuneEnrollmentIdsCache *)cache
{
    @synchronized(self)
    {
        if (cache == nil) return;
        
        s_sharedCache = cache;
    }
}

+ (MSIDIntuneEnrollmentIdsCache *)sharedCache
{
    @synchronized(self)
    {
        if (!s_sharedCache)
        {
            s_sharedCache = [[MSIDIntuneEnrollmentIdsCache alloc] initWithDataSource:[MSIDIntuneInMemoryCacheDataSource new]];
        }
        
        return s_sharedCache;
    }
}

- (NSString *)enrollmentIdForUserId:(NSString *)userId
                            context:(id<MSIDRequestContext>)context
                              error:(NSError **)error
{
    NSDictionary *jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    NSArray *enrollIds = [jsonDictionary objectForKey:MSID_INTUNE_ENROLLMENT_ID_ARRAY];
    for (NSDictionary *enrollIdDic in enrollIds)
    {
        if ([enrollIdDic[MSID_INTUNE_USER_ID] isEqualToString:userId])
        {
            return enrollIdDic[MSID_INTUNE_ENROLL_ID];
        }
    }
    
    return nil;
}

- (NSString *)enrollmentIdForUserObjectId:(NSString *)userObjectId
                                 tenantId:(NSString *)tenantId
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    if (!userObjectId || !tenantId) return nil;
    
    NSDictionary *jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    NSArray *enrollIds = [jsonDictionary objectForKey:MSID_INTUNE_ENROLLMENT_ID_ARRAY];
    for (NSDictionary *enrollIdDic in enrollIds)
    {
        if ([enrollIdDic[MSID_INTUNE_OID] isEqualToString:userObjectId] &&
            [enrollIdDic[MSID_INTUNE_TID] isEqualToString:tenantId])
        {
            return enrollIdDic[MSID_INTUNE_ENROLL_ID];
        }
    }
    
    return nil;
}

- (NSString *)enrollmentIdForHomeAccountId:(NSString *)homeAccountId
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError **)error
{
    NSDictionary *jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    NSArray *enrollIds = [jsonDictionary objectForKey:MSID_INTUNE_ENROLLMENT_ID_ARRAY];
    for (NSDictionary *enrollIdDic in enrollIds)
    {
        if ([enrollIdDic[MSID_INTUNE_HOME_ACCOUNT_ID] isEqualToString:homeAccountId])
        {
            return enrollIdDic[MSID_INTUNE_ENROLL_ID];
        }
    }
    
    return nil;
}

- (NSString *)enrollmentIdForHomeAccountId:(NSString *)homeAccountId
                              legacyUserId:(NSString *)legacyUserId
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError **)error
{
    NSString *enrollmentId = nil;
    
    // If homeAccountID is provided, try to match by it first.
    if (homeAccountId)
    {
        enrollmentId = [self enrollmentIdForHomeAccountId:homeAccountId context:context error:error];
        if (enrollmentId)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Enrollment id read from intune cache : %@.", MSID_PII_LOG_MASKABLE(enrollmentId));
            return enrollmentId;
        }
    }
    
    // If legacy userID is provided, try to match by userID.
    if (legacyUserId)
    {
        enrollmentId = [self enrollmentIdForUserId:legacyUserId context:context error:error];
        if (enrollmentId)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Enrollment id read from intune cache : %@.", MSID_PII_LOG_MASKABLE(enrollmentId));
            return enrollmentId;
        }
    }
    
    // If we haven't found an exact match yet, fallback to any enrollment ID to support no userID or single userID scenarios.
    return [self enrollmentIdIfAvailableWithContext:context error:error];
}

- (NSString *)enrollmentIdIfAvailableWithContext:(id<MSIDRequestContext>)context
                                           error:(NSError **)error
{
    NSDictionary *jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    NSArray *enrollIds = [jsonDictionary objectForKey:MSID_INTUNE_ENROLLMENT_ID_ARRAY];
    NSDictionary *enrollIdDic = enrollIds.firstObject;
    NSString *enrollmentId = enrollIdDic[MSID_INTUNE_ENROLL_ID];
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Enrollment id read from intune cache : %@.", enrollmentId ? MSID_PII_LOG_MASKABLE(enrollmentId) : enrollmentId);
    return enrollmentId;
}

- (BOOL)setEnrollmentIdsJsonDictionary:(NSDictionary *)jsonDictionary
                               context:(id<MSIDRequestContext>)context
                                 error:(NSError **)error
{
    if (![self isValid:jsonDictionary context:context error:error]) return NO;
    
    [self.dataSource setJsonDictionary:jsonDictionary forKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    return YES;
}

- (NSDictionary *)enrollmentIdsJsonDictionaryWithContext:(id<MSIDRequestContext>)context
                                                   error:(NSError **)error
{
    __auto_type jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    return jsonDictionary;
}

- (void)clear
{
    [self.dataSource removeObjectForKey:MSID_INTUNE_ENROLLMENT_ID_KEY];
}

#pragma mark - Private

- (BOOL)isValid:(NSDictionary *)json
        context:(id<MSIDRequestContext>)context
          error:(NSError **)error
{
    if (!json) return YES;
    
    NSString *errorDescription = @"Intune Enrollment ID JSON structure is incorrect.";
    __auto_type validationError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil, context.correlationId, nil, NO);
    
    if (![json isKindOfClass:NSDictionary.class])
    {
        if (error) *error = validationError;
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Enrollment ID JSON structure is incorrect (json not a dictionary).");
        
        return NO;
    }
    
    NSArray *enrollIds = json[MSID_INTUNE_ENROLLMENT_ID_ARRAY];
    
    if (![enrollIds isKindOfClass:NSArray.class])
    {
        if (error) *error = validationError;
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Enrollment ID JSON structure is incorrect (enrollIds not an array).");
        
        return NO;
    }
    
    for (NSDictionary *enrollIdDic in enrollIds)
    {
        if (![enrollIdDic isKindOfClass:NSDictionary.class])
        {
            if (error) *error = validationError;
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Enrollment ID JSON structure is incorrect (enrollIdDic not an array).");
            
            return NO;
        }
        
        NSString *enrollId = enrollIdDic[MSID_INTUNE_ENROLL_ID];
        if (enrollId)
        {
            if (![enrollId isKindOfClass:NSString.class])
            {
                if (error) *error = validationError;
                MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Enrollment ID JSON structure is incorrect (enrollId not a string).");
                
                return NO;
            }
        }
    }
    
    return YES;
}

@end
