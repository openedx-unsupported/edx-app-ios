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

#import "MSIDJsonSerializer.h"
#import "MSIDJsonObject.h"
#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDAppMetadataCacheItem.h"
#import "NSJSONSerialization+MSIDExtensions.h"

@implementation MSIDJsonSerializer

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        // Normalize by default unless developer has explicitly verified that normalization is not needed
        _normalizeJSON = YES;
    }
    
    return self;
}

#pragma mark - MSIDJsonSerializing

- (NSData *)toJsonData:(id<MSIDJsonSerializable>)serializable
               context:(id<MSIDRequestContext>)context
                 error:(NSError **)error
{
    __auto_type jsonDictionary = [serializable jsonDictionary];
    if (!jsonDictionary)
    {
        return nil;
    }
    
    NSError *internalError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                   options:0
                                                     error:&internalError];
    if (internalError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, context, @"Failed to serialize to json data, error: %@", MSID_PII_LOG_MASKABLE(internalError));
        if (error) *error = internalError;
        return nil;
    }
    
    return data;
}

- (id<MSIDJsonSerializable>)fromJsonData:(NSData *)data
                                  ofType:(Class)klass
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    NSParameterAssert([klass conformsToProtocol:@protocol(MSIDJsonSerializable)]);
    if (![klass conformsToProtocol:@protocol(MSIDJsonSerializable)]) return nil;
    
    NSError *internalError;
    NSDictionary *jsonDictionary = [self deserializeJSON:data error:&internalError];
    
    if (internalError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Failed to deserialize json object, error: %@", MSID_PII_LOG_MASKABLE(internalError));
        
        if (error) *error = internalError;
        return nil;
    }
    
    return [[klass alloc] initWithJSONDictionary:jsonDictionary error:error];
}

- (NSString *)toJsonString:(id<MSIDJsonSerializable>)serializable
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    NSData *jsonData = [self toJsonData:serializable context:context error:error];
    if (!jsonData) return nil;
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (id<MSIDJsonSerializable>)fromJsonString:(NSString *)jsonString
                                    ofType:(Class)klass
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError **)error
{
    NSParameterAssert([klass conformsToProtocol:@protocol(MSIDJsonSerializable)]);
    if (![klass conformsToProtocol:@protocol(MSIDJsonSerializable)]) return nil;
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [self fromJsonData:jsonData ofType:klass context:context error:error];
}

#pragma mark - Private

- (NSDictionary *)deserializeJSON:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (!data)
    {
        if (error)
        {
            NSString *errorDescription = [NSString stringWithFormat:@"Attempt to initialize JSON object with nil data in (%@)", NSStringFromClass(self.class)];
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil, nil, nil, NO);
        }
        
        return nil;
    }
    
    if (self.normalizeJSON)
    {
        return [NSJSONSerialization msidNormalizedDictionaryFromJsonData:data error:error];
    }
    
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:error];
}

@end
