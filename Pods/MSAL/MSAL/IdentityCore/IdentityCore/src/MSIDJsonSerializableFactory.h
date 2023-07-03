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

NS_ASSUME_NONNULL_BEGIN

@interface MSIDJsonSerializableFactory : NSObject

/*!
 Bind class type with specifc class type key in json paylod.
 This method is tread safe.
 @param aClass Class which will be associated with classType in this factory.
 @param classType Class type under which class will be registered in this factory.
 */
+ (void)registerClass:(Class<MSIDJsonSerializable>)aClass forClassType:(NSString *)classType;

/*!
Map key, key value and kind of class to specific classType.
For example: "MSIDAuthority|provider_type|provider_aad_v2" can be mapped to "authority_aad".
This method is tread safe.
@param key Key in json payload.
@param keyValue Value of provided key in json payload.
@param aClass Class which is used to verify created class instance is a kind of it.
@param classType Class type under which class will be registered in this factory.
*/
+ (void)mapJSONKey:(NSString *)key keyValue:(NSString *)keyValue kindOfClass:(Class)aClass toClassType:(NSString *)classType;

/*!
 Unbind all registered classes.
 This method is tread safe.
 */
+ (void)unregisterAll;

/*!
 Create instance of class from the provided json payload.
 This method is not thread safe.
 @param json JSON payload.
 @param classTypeJSONKey Key in json payload which should be used to get class type. All classes are registered
 under this class type in this factory.
 @param aClass Verify created class instance is kind of aClass.
 */
+ (nullable id<MSIDJsonSerializable>)createFromJSONDictionary:(NSDictionary *)json
                                             classTypeJSONKey:(NSString *)classTypeJSONKey
                                            assertKindOfClass:(Class)aClass
                                                        error:(NSError **)error;

/*!
 Create instance of class from the provided json payload.
 This method is not thread safe.
 @param json JSON payload.
 @param classType Class type under which class is registered in this factory.
 @param aClass Verify created class instance is kind of aClass.
*/
+ (nullable id<MSIDJsonSerializable>)createFromJSONDictionary:(NSDictionary *)json
                                                    classType:(NSString *)classType
                                            assertKindOfClass:(Class)aClass
                                                        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
