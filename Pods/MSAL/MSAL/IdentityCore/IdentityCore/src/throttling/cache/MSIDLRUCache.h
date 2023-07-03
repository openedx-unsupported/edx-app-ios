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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.  

NS_ASSUME_NONNULL_BEGIN

/**
 Thread-safe LRU cache that supports any object and key type, as long as only one object and key type is used for each instance.
 */
@interface MSIDLRUCache <KeyType, ObjectType>: NSObject

@property (nonatomic, readonly) NSUInteger cacheSize; //size of the LRU cache
@property (nonatomic, readonly) NSUInteger numCacheRecords; //number of valid records currently stored in the LRU cache
@property (nonatomic, readonly) NSUInteger cacheUpdateCount; //number of times cache entries have been updated
@property (nonatomic, readonly) NSUInteger cacheEvictionCount; //number of times cache entries have been evicted
@property (nonatomic, readonly) NSUInteger cacheAddCount; //number of times cache entry has been added
@property (nonatomic, readonly) NSUInteger cacheRemoveCount; //number of times cache entry has been removed

/**
 initialize LRU cache with custom size
 */
- (instancetype)initWithCacheSize:(NSUInteger)cacheSize;

/**
 create a shared singleton instance with default size, currently set to 1000
 */
+ (MSIDLRUCache *)sharedInstance;

/**
add a new object to the front of LRU cache.
if object already exists, move to the front of LRU cache
if LRU cache is full, it will invalidate least recently used entry, and then add this new input object mapped by input key.
if nil object or key is provided, this API will return NO, and an error will be generated.
 */
- (BOOL)setObject:(ObjectType)cacheRecord
           forKey:(KeyType)key
            error:(NSError * _Nullable * _Nullable)error;

/**
remove object that corresponds to the given key.
If nil key is provided, or no object exists that maps to the input key, this API will return NO, and an error will be generated.
 */
- (BOOL)removeObjectForKey:(KeyType)key
                     error:(NSError * _Nullable * _Nullable)error;

/**
 retrieve object corresponding to the input key, and move the object to the front of LRU cache.
 */
- (nullable ObjectType)objectForKey:(KeyType)key
                              error:(NSError * _Nullable * _Nullable)error;

/**
 return all cached elements sorted from most recently used (first) to least recently used (last)
*/

- (nullable NSArray<ObjectType> *)enumerateAndReturnAllObjects;

/**
 clear all objects in cache
 */
- (BOOL)removeAllObjects:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
