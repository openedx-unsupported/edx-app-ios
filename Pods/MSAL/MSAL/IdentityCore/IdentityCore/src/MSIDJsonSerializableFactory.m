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

#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializable.h"

static NSMutableDictionary<NSString *, Class<MSIDJsonSerializable>> *s_container = nil;
static NSMutableDictionary<NSString *, NSString *> *s_keysMap = nil;

@implementation MSIDJsonSerializableFactory

+ (void)registerClass:(Class<MSIDJsonSerializable>)aClass forClassType:(NSString *)classType
{
    if (!aClass || !classType) return;
    if (![classType isKindOfClass:NSString.class]) return;
    if (![aClass conformsToProtocol:@protocol(MSIDJsonSerializable)]) return;
    
    @synchronized(self)
    {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            s_container = [NSMutableDictionary new];
        });
        
        s_container[classType] = aClass;
    }
}

+ (void)mapJSONKey:(NSString *)key
          keyValue:(NSString *)keyValue
       kindOfClass:(Class)aClass
       toClassType:(NSString *)classType
{
    if (!key || !keyValue || !aClass || !classType) return;
    if (![key isKindOfClass:NSString.class]) return;
    if (![keyValue isKindOfClass:NSString.class]) return;
    if (![aClass conformsToProtocol:@protocol(MSIDJsonSerializable)]) return;
    if (![classType isKindOfClass:NSString.class]) return;
    
    @synchronized(self)
    {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            s_keysMap = [NSMutableDictionary new];
        });
        
        NSString *compositeKey = [self mappingKeyForClass:aClass key:key keyValue:keyValue];
        s_keysMap[compositeKey] = classType;
    }
}

+ (void)unregisterAll
{
    @synchronized(self)
    {
        [s_container removeAllObjects];
        [s_keysMap removeAllObjects];
    }
}

+ (id<MSIDJsonSerializable>)createFromJSONDictionary:(NSDictionary *)json
                                    classTypeJSONKey:(NSString *)classTypeJSONKey
                                   assertKindOfClass:(Class)aClass
                                               error:(NSError **)error
{
    if (![json msidAssertType:NSString.class ofKey:classTypeJSONKey required:YES error:error]) return nil;
    NSString *classTypeValue = json[classTypeJSONKey];
    
    NSError *localError;
    id<MSIDJsonSerializable> instance = [self createFromJSONDictionary:json containerKey:classTypeValue assertKindOfClass:aClass error:&localError];
    
    if (instance) return instance;
    
    // There is no class registered under `classTypeValue`. Let's see if we have a mapping for classTypeJSONKey.
    NSString *mappedClassTypeValue = [self classTypeForJSONKey:classTypeJSONKey keyValue:classTypeValue kindOfClass:aClass];
    
     // If there is no mapping, return original error.
    if (!mappedClassTypeValue)
    {
        if (error) *error = localError;
        return nil;
    }
    
    // At this point we have mapped class type. Let's use it to create instance of class.
    return [self createFromJSONDictionary:json containerKey:mappedClassTypeValue assertKindOfClass:aClass error:error];
}

+ (id<MSIDJsonSerializable>)createFromJSONDictionary:(NSDictionary *)json
                                      classType:(NSString *)classTypeValue
                                   assertKindOfClass:(Class)aClass
                                               error:(NSError **)error
{
    return [self createFromJSONDictionary:json containerKey:classTypeValue assertKindOfClass:aClass error:error];
}

#pragma mark - Private

+ (NSString *)classTypeForJSONKey:(NSString *)key keyValue:(NSString *)keyValue kindOfClass:(Class)aClass
{
    NSString *compositeKey = [self mappingKeyForClass:aClass key:key keyValue:keyValue];
    return s_keysMap[compositeKey];
}

+ (NSString *)mappingKeyForClass:(Class)aClass key:(NSString *)key keyValue:(NSString *)keyValue
{
    return [NSString stringWithFormat:@"%@|%@|%@", NSStringFromClass(aClass), key, keyValue];
}

+ (id<MSIDJsonSerializable>)createFromJSONDictionary:(NSDictionary *)json
                                        containerKey:(NSString *)containerKey
                                   assertKindOfClass:(Class)aClass
                                               error:(NSError **)error
{
    Class class = (Class<MSIDJsonSerializable>)s_container[containerKey];
    
    if (!class)
    {
        if (error)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Failed to create object from json, class: %@ wasn't registered in factory under %@ key.", aClass, containerKey];
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidDeveloperParameter,
                                     errorMessage,
                                     nil, nil, nil, nil, nil, NO);
            
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"%@", errorMessage);
        }
        
        return nil;
    }
    
    id<MSIDJsonSerializable> classInstance = [[(Class)class alloc] initWithJSONDictionary:json error:error];
    if (!classInstance) return nil;
    
    if (![classInstance isKindOfClass:aClass])
    {
        if (error)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Failed to create object from json, created class instance is not of expected kind: %@.", aClass];
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidDeveloperParameter,
                                     errorMessage,
                                     nil, nil, nil, nil, nil, NO);
            
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"%@", errorMessage);
        }
        
        return nil;
    }
    
    return classInstance;
}

@end
