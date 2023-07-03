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

@protocol MSIDJsonSerializable;
@protocol MSIDRequestContext;

@protocol MSIDJsonSerializing <NSObject>

// JSON Data.
- (NSData *)toJsonData:(id<MSIDJsonSerializable>)serializable
               context:(id<MSIDRequestContext>)context
                 error:(NSError *__autoreleasing *)error;

- (id<MSIDJsonSerializable>)fromJsonData:(NSData *)data
                                  ofType:(Class)klass
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError *__autoreleasing *)error;

// JSON String.
- (NSString *)toJsonString:(id<MSIDJsonSerializable>)serializable
                   context:(id<MSIDRequestContext>)context
                     error:(NSError *__autoreleasing *)error;

- (id<MSIDJsonSerializable>)fromJsonString:(NSString *)jsonString
                                    ofType:(Class)klass
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError *__autoreleasing *)error;

@end
