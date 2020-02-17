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

#import <Foundation/Foundation.h>
#import "MSIDJsonSerializable.h"

#define MSID_JSON_ACCESSOR(KEY, GETTER) DICTIONARY_READ_PROPERTY_IMPL(_json, KEY, GETTER)
#define MSID_JSON_MUTATOR(KEY, SETTER) DICTIONARY_WRITE_PROPERTY_IMPL(_json, KEY, SETTER)

#define MSID_JSON_RW(KEY, GETTER, SETTER) \
    MSID_JSON_ACCESSOR(KEY, GETTER) \
    MSID_JSON_MUTATOR(KEY, SETTER)

@interface MSIDJsonObject : NSObject <NSCopying, MSIDJsonSerializable>
{
    NSMutableDictionary *_json;
}

- (instancetype)initWithJSONData:(NSData *)data
                           error:(NSError * __autoreleasing *)error;

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                                 error:(NSError * __autoreleasing *)error NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)jsonDictionary;
- (NSData *)serialize:(NSError * __autoreleasing *)error;

- (BOOL)isEqualToJsonObject:(MSIDJsonObject *)jsonObject;

@end
