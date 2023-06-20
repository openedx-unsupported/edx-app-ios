//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDJsonObject.h"
#import "NSJSONSerialization+MSIDExtensions.h"

@implementation MSIDJsonObject

- (instancetype)init
{
    return [self initWithJSONDictionary:[NSDictionary dictionary] error:nil];
}

- (instancetype)initWithJSONData:(NSData *)data
                           error:(NSError * __autoreleasing *)error
{
    if (!data)
    {
        if (error)
        {
            NSString *errorDescription = [NSString stringWithFormat:@"Attempt to initialize JSON object (%@) with nil data", NSStringFromClass(self.class)];
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    NSDictionary *json = [NSJSONSerialization msidNormalizedDictionaryFromJsonData:data error:error];
    
    if (!json)
    {
        return nil;
    }
    
    return [self initWithJSONDictionary:json error:error];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                                 error:(NSError * __autoreleasing *)error
{
    if (!json)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Attempt to initialize JSON object with nil dictionary", nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _json = [json mutableCopy];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIDJsonObject *item = [[MSIDJsonObject allocWithZone:zone] init];
    item->_json = [_json copyWithZone:zone];
    return item;
}

- (NSDictionary *)jsonDictionary
{
    return _json;
}

- (NSData *)serialize:(NSError * __autoreleasing *)error
{
    return [NSJSONSerialization dataWithJSONObject:self.jsonDictionary
                                           options:0
                                             error:error];
}

- (BOOL)isEqualToJsonObject:(MSIDJsonObject *)jsonObject
{
    if (!jsonObject)
    {
        return NO;
    }

    BOOL result = YES;
    result &= (!_json && !jsonObject->_json) || [_json isEqualToDictionary:jsonObject->_json];

    return result;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:MSIDJsonObject.class])
    {
        return NO;
    }

    return [self isEqualToJsonObject:(MSIDJsonObject *)object];
}

- (NSUInteger)hash
{
    return [_json hash];
}

@end
