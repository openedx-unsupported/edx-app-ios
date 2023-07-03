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
#import "NSDictionary+MSIDExtensions.h"
#import "NSString+MSIDExtensions.h"

@implementation NSDictionary (MSIDExtensions)

+ (NSDictionary *)msidDictionaryFromURLEncodedString:(NSString *)string
{
    return [self msidDictionaryFromURLEncodedString:string isFormEncoded:NO];
}

// Decodes a www-form-urlencoded string into a dictionary of key/value pairs.
// Always returns a dictionary, even if the string is nil, empty or contains no pairs
+ (NSDictionary *)msidDictionaryFromWWWFormURLEncodedString:(NSString *)string
{
    return [self msidDictionaryFromURLEncodedString:string isFormEncoded:YES];
}

+ (NSDictionary *)msidDictionaryFromURLEncodedString:(NSString *)string
                                       isFormEncoded:(BOOL)isFormEncoded
{
    if ([NSString msidIsStringNilOrBlank:string])
    {
        return nil;
    }
    
    NSArray *queries = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryDict = [NSMutableDictionary new];
    
    for (NSString *query in queries)
    {
        NSArray *queryElements = [query componentsSeparatedByString:@"="];
        
        NSString *key = isFormEncoded ? [queryElements[0] msidTrimmedString].msidWWWFormURLDecode : [queryElements[0] msidTrimmedString].msidURLDecode;
        if ([NSString msidIsStringNilOrBlank:key])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Query parameter must have a key");
            continue;
        }
        
        if (queryElements.count > 2)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Query parameter contains more than one '=' for key: %@", key);
            continue;
        }
        
        NSString *value = @"";
        if (queryElements.count == 2)
        {
            value = isFormEncoded ? [queryElements[1] msidTrimmedString].msidWWWFormURLDecode : [queryElements[1] msidTrimmedString].msidURLDecode;
        }
        
        [queryDict setValue:value forKey:key];
    }
    
    return queryDict;
}

- (NSString *)msidURLEncode
{
    return [NSString msidURLEncodedStringFromDictionary:self];
}

- (NSString *)msidWWWFormURLEncode
{
    return [NSString msidWWWFormURLEncodedStringFromDictionary:self];
}

- (NSDictionary *)msidDictionaryByRemovingFields:(NSArray *)fieldsToRemove
{
    NSMutableDictionary *mutableDict = [self mutableCopy];
    [mutableDict removeObjectsForKeys:fieldsToRemove];
    return mutableDict;
}

- (BOOL)msidAssertType:(Class)type ofKey:(NSString *)key required:(BOOL)required error:(NSError **)error
{
    return [self msidAssertTypeIsOneOf:@[type] ofKey:key required:required error:error];
}

- (BOOL)msidAssertTypeIsOneOf:(NSArray<Class> *)types ofKey:(NSString *)key required:(BOOL)required error:(NSError **)error
{
    return [self msidAssertTypeIsOneOf:types ofKey:key required:required context:nil errorCode:MSIDErrorInvalidInternalParameter error:error];
}

- (BOOL)msidAssertTypeIsOneOf:(NSArray<Class> *)types
                        ofKey:(NSString *)key
                     required:(BOOL)required
                      context:(id<MSIDRequestContext>)context
                    errorCode:(NSInteger)errorCode
                        error:(NSError **)error
{
    id obj = self[key];
    if (!obj && !required) return YES;
    
    NSString *message;
    if (!obj)
    {
        message = [NSString stringWithFormat:@"%@ key is missing in dictionary.", key];
    }
    else
    {
        BOOL matched = NO;
        __auto_type typesSet = [[NSSet alloc] initWithArray:types];
        for (Class type in typesSet)
        {
            if ([obj isKindOfClass:type])
            {
                matched = YES;
                break;
            }
        }
        
        if (!matched)
        {
            NSString *allowedTypesString = [types componentsJoinedByString:@","];
            message = [NSString stringWithFormat:@"%@ key in dictionary is not of expected type. Allowed types: %@.", key, allowedTypesString];
        }
    }
    
    if (message)
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, errorCode, message, nil, nil, nil, context.correlationId, nil, YES);
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"%@", message);
        
        return NO;
    }
    
    return YES;
}

- (NSString *)msidJSONSerializeWithContext:(id<MSIDRequestContext>)context
{
    NSError *serializationError = nil;
    NSData *serializedData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&serializationError];

    if (!serializedData)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Failed to serialize data with error %@", MSID_PII_LOG_MASKABLE(serializationError));
        
        return nil;
    }

    return [[NSString alloc] initWithData:serializedData encoding:NSUTF8StringEncoding];
}

// TODO: verify this is still necessary as it was done in ADAL
- (NSDictionary *)msidDictionaryWithoutNulls
{
    NSMutableDictionary *cleanedDictionary = [NSMutableDictionary new];

    for (NSString *key in self.allKeys)
    {
        NSString *val = [self valueForKey:key];

        if ([val isKindOfClass:[NSString class]]
            && ![val isEqualToString:@"(null)"])
        {
            cleanedDictionary[key] = val;
        }
    }

    return cleanedDictionary;
}

- (NSDictionary *)msidNormalizedJSONDictionary
{
    NSMutableDictionary *normalizedDictionary = [NSMutableDictionary new];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[NSDictionary class]])
        {
            normalizedDictionary[key] = [[self objectForKey:key] msidNormalizedJSONDictionary];
        }
        else if ([obj isKindOfClass:[NSArray class]])
        {
            NSMutableArray *normalizedArray = [NSMutableArray new];
            
            for (id arrayObject in (NSArray *)obj)
            {
                if ([arrayObject isKindOfClass:[NSDictionary class]])
                {
                    [normalizedArray addObject:[arrayObject msidNormalizedJSONDictionary]];
                }
                else if (![arrayObject isKindOfClass:[NSNull class]])
                {
                    [normalizedArray addObject:arrayObject];
                }
            }
            
            normalizedDictionary[key] = normalizedArray;
        }
        else if (![obj isKindOfClass:[NSNull class]])
        {
            normalizedDictionary[key] = [self objectForKey:key];
        }
    }];
    
    return normalizedDictionary;
}

- (NSString *)msidStringObjectForKey:(NSString *)key
{
    return [self msidObjectForKey:key ofClass:[NSString class]];
}

- (NSInteger)msidIntegerObjectForKey:(NSString *)key
{
    if ([self msidAssertTypeIsOneOf:@[NSString.class, NSNumber.class] ofKey:key required:NO error:nil])
    {
        return [self[key] integerValue];
    }
    
    return 0;
}

- (BOOL)msidBoolObjectForKey:(NSString *)key
{
    if ([self msidAssertTypeIsOneOf:@[NSString.class, NSNumber.class] ofKey:key required:NO error:nil])
    {
        return [self[key] boolValue];
    }
    
    return NO;
}

- (id)msidObjectForKey:(NSString *)key ofClass:(Class)requiredClass
{
    id object = [self objectForKey:key];
    
    if (object && [object isKindOfClass:requiredClass])
    {
        return object;
    }
    
    return nil;
}

- (NSMutableDictionary *)mutableDeepCopy
{
    NSMutableDictionary *returnDict = [[NSMutableDictionary alloc] initWithCapacity:[self count]];
    NSArray *keys = [self allKeys];
    for (id key in keys)
    {
        
        id value = [self objectForKey:key];
        id copy = nil;
        if ([value respondsToSelector:@selector(mutableDeepCopy)])
        {
            copy = [value mutableDeepCopy];
        }
        else if ([value respondsToSelector:@selector(mutableCopyWithZone:)])
        {
            copy = [value mutableCopy];
        }
        if (copy == nil)
        {
            copy = [value copy];
        }
        
        [returnDict setObject:copy forKey:key];
    }
    
    return returnDict;
}

@end
