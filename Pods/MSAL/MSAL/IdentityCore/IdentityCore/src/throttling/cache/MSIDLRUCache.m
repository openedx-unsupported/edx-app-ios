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

#import "MSIDLRUCache.h"

static NSString *const HEAD_SIGNATURE = @"HEAD";
static NSString *const TAIL_SIGNATURE = @"TAIL";

#define DEFAULT_CACHE_SIZE 1000
#define DEFAULT_SIGNATURE_LENGTH 8
#define DEFAULT_CACHE_OFFSET_SIZE 2

//Helper class
@interface MSIDLRUCacheNode : NSObject

@property (nonatomic, readonly) NSString *signature;
@property (nonatomic) NSMutableString *prevSignature;
@property (nonatomic) NSMutableString *nextSignature;
@property (nonatomic) id cacheRecord;

- (instancetype)initWithSignature:(NSString *)signature
                    prevSignature:(NSString *)prevSignature
                    nextSignature:(NSString *)nextSignature
                      cacheRecord:(id)cacheRecord;

@end


@implementation MSIDLRUCacheNode

- (instancetype)initWithSignature:(NSString *)signature
                    prevSignature:(NSString *)prevSignature
                    nextSignature:(NSString *)nextSignature
                      cacheRecord:(id)cacheRecord
{
    self = [super init];
    if (self)
    {
        _signature = signature;
        _prevSignature = [prevSignature mutableCopy];
        _nextSignature = [nextSignature mutableCopy];
        _cacheRecord = cacheRecord;
    }
    return self;
}

@end

//Main class
@interface MSIDLRUCache ()

@property (nonatomic) NSUInteger cacheSizeInt;
@property (nonatomic) NSUInteger cacheUpdateCountInt;
@property (nonatomic) NSUInteger cacheEvictionCountInt;
@property (nonatomic) NSUInteger cacheAddCountInt;
@property (nonatomic) NSUInteger cacheRemoveCountInt;
@property (nonatomic) NSMutableDictionary *container;
@property (nonatomic) NSMutableDictionary *keySignatureMap;
@property (nonatomic) dispatch_queue_t synchronizationQueue;

@end

@implementation MSIDLRUCache

- (NSUInteger)cacheSize
{
    return self.cacheSizeInt - DEFAULT_CACHE_OFFSET_SIZE;
}

- (NSUInteger)numCacheRecords
{
    return self.container.allKeys.count - DEFAULT_CACHE_OFFSET_SIZE;
}

- (NSUInteger)cacheUpdateCount
{
    return self.cacheUpdateCountInt;
}

- (NSUInteger)cacheEvictionCount
{
    return self.cacheEvictionCountInt;
}

- (NSUInteger)cacheAddCount
{
    return self.cacheAddCountInt;
}

- (NSUInteger)cacheRemoveCount
{
    return self.cacheRemoveCountInt;
}

- (instancetype)initWithCacheSize:(NSUInteger)cacheSize
{
    self = [super init];
    if (self)
    {
        _cacheSizeInt = cacheSize + DEFAULT_CACHE_OFFSET_SIZE;
        _cacheUpdateCountInt = 0;
        _cacheEvictionCountInt = 0;
        //create dummy head and tail
        MSIDLRUCacheNode *head = [[MSIDLRUCacheNode alloc] initWithSignature:HEAD_SIGNATURE
                                                               prevSignature:nil
                                                               nextSignature:TAIL_SIGNATURE
                                                                 cacheRecord:nil];
        
        MSIDLRUCacheNode *tail = [[MSIDLRUCacheNode alloc] initWithSignature:TAIL_SIGNATURE
                                                               prevSignature:HEAD_SIGNATURE
                                                               nextSignature:nil
                                                                 cacheRecord:nil];
        
        //create concurrent queue and container dictionary
        NSString *queueName = [NSString stringWithFormat:@"com.microsoft.msidlrucache-%@", [NSUUID UUID].UUIDString];
        _synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        _container = [NSMutableDictionary new];
        _keySignatureMap = [NSMutableDictionary new];
        
        [self.container setObject:head forKey:HEAD_SIGNATURE];
        [self.container setObject:tail forKey:TAIL_SIGNATURE];
    }
    return self;
}

+ (MSIDLRUCache *)sharedInstance
{
    static MSIDLRUCache *m_service;
    static dispatch_once_t once_token;
    
    dispatch_once(&once_token, ^{
        m_service = [[MSIDLRUCache alloc] initWithCacheSize:DEFAULT_CACHE_SIZE];
    });
    
    return m_service;
}

/* add new node to the front of LRU cache.
if node already exists, update and move it to the front of LRU cache */
- (BOOL)setObject:(id)cacheRecord
           forKey:(id)key
            error:(NSError **)error
{
    __block NSError *subError = nil;
    BOOL result = YES;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (self.cacheSizeInt <= DEFAULT_CACHE_OFFSET_SIZE)
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: cache was initialized with size less than 1. Cannot write due to insufficient size.", nil, nil, nil, nil, nil, NO);
        }
        
        else if (!cacheRecord || !key)
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: invalid input. record and/or key is nil", nil, nil, nil, nil, nil, NO);
        }
        
        else
        {
            //node already exists - simply move it to front
            if ([self.keySignatureMap objectForKey:key])
            {
                [self objectForKeyImpl:[self.keySignatureMap objectForKey:key]
                                 error:&subError];
            }
            
            else
            {
                //if cache is full, invalidate least recently used entry
                if (self.container.allKeys.count >= self.cacheSizeInt)
                {
                    MSIDLRUCacheNode *tailNode = [self.container objectForKey:TAIL_SIGNATURE];
                    [self removeObjectForKeyImpl:tailNode.prevSignature
                                           error:&subError];
                    self.cacheEvictionCountInt++;
                }
                NSString *signature = [self mapKeyToSignature:key];
                MSIDLRUCacheNode *newNode = [[MSIDLRUCacheNode alloc] initWithSignature:signature
                                                                          prevSignature:nil
                                                                          nextSignature:nil
                                                                            cacheRecord:cacheRecord];
                [self addToFrontImpl:newNode];
                self.cacheAddCountInt++;
            }
        }
    });
    
    if (subError)
    {
        result = NO;
    }
    
    if (error)
    {
        *error = subError;
    }
    return result;
}


- (BOOL)removeObjectForKey:(id)key
                     error:(NSError **)error
{
    __block NSError *subError = nil;
    BOOL result = YES;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (!key)
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: invalid input during removal - key is nil", nil, nil, nil, nil, nil, NO);
        }
        
        else if (![self.keySignatureMap objectForKey:key])
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: Unable to find valid signature for the input key during removal", nil, nil, nil, nil, nil, NO);
        }
        
        else
        {
            NSString *signature = [self.keySignatureMap objectForKey:key];
            [self.keySignatureMap removeObjectForKey:key];
            [self removeObjectForKeyImpl:signature
                                   error:&subError];
            self.cacheRemoveCountInt++;
        }
    });
    
    if (subError)
    {
        result = NO;
    }
    
    if (error)
    {
        *error = subError;
    }
    return result;
}

- (BOOL)removeObjectForKeyImpl:(NSString *)signature
                         error:(NSError **)error
{
    if (!signature)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: invalid input during removal - signature is nil", nil, nil, nil, nil, nil, NO);
        }
        return NO;
        
    }
    
    else if (![self.container objectForKey:signature])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: Unable to find valid node for the input signature during removal", nil, nil, nil, nil, nil, NO);
        }
        return NO;
    }
    
    MSIDLRUCacheNode *node = [self.container objectForKey:signature];
    MSIDLRUCacheNode *prevNode = [self.container objectForKey:node.prevSignature];
    MSIDLRUCacheNode *nextNode = [self.container objectForKey:node.nextSignature];

    MSIDLRUCacheNode *newPrevNode = [[MSIDLRUCacheNode alloc] initWithSignature:prevNode.signature
                                                                  prevSignature:prevNode.prevSignature
                                                                  nextSignature:node.nextSignature
                                                                    cacheRecord:prevNode.cacheRecord];
    
    MSIDLRUCacheNode *newNextNode = [[MSIDLRUCacheNode alloc] initWithSignature:nextNode.signature
                                                                  prevSignature:node.prevSignature
                                                                  nextSignature:nextNode.nextSignature
                                                                    cacheRecord:nextNode.cacheRecord];


    [self.container setObject:newPrevNode forKey:newPrevNode.signature];
    [self.container setObject:newNextNode forKey:newNextNode.signature];
    
    [self.container removeObjectForKey:signature];
    return YES;
}

//retrieve cache record from the corresponding node, and move the node to the front of LRU cache.
- (id)objectForKey:(id)key
             error:(NSError **)error
{
    __block id cacheRecord;
    __block NSError *subError = nil;
    
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (!key)
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorThrottleCacheInvalidSignature, @"MSIDLRUCache Error: invalid input during retrieval - key is nil.", nil, nil, nil, nil, nil, NO);
        }
        else if (![self.keySignatureMap objectForKey:key])
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorThrottleCacheNoRecord, @"MSIDLRUCache Error: Unable to find valid signature for the input key during retrieval", nil, nil, nil, nil, nil, NO);
        }
        if (subError) return;
        cacheRecord = [self objectForKeyImpl:[self.keySignatureMap objectForKey:key]
                                       error:&subError];
    });
    if (subError)
    {
        cacheRecord = nil;
    }
    
    if (error)
    {
        *error = subError;
    }

    return cacheRecord;
}

- (id)objectForKeyImpl:(NSString *)signature
                 error:(NSError **)error
{
    if (!signature)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorThrottleCacheInvalidSignature, @"MSIDLRUCache Error: invalid input during retrieval - signature is nil", nil, nil, nil, nil, nil, NO);
        }
        return nil;
    }
    
    else if (![self.container objectForKey:signature])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorThrottleCacheNoRecord, @"MSIDLRUCache Error: Unable to find valid node for the input signature during retrieval", nil, nil, nil, nil, nil, NO);
        }
        return nil;
    }
    
    //retrieve node
    MSIDLRUCacheNode *node = [self.container objectForKey:signature];
    MSIDLRUCacheNode *newNode = [[MSIDLRUCacheNode alloc] initWithSignature:node.signature
                                                              prevSignature:node.prevSignature
                                                              nextSignature:node.nextSignature
                                                                cacheRecord:node.cacheRecord];
    self.cacheUpdateCountInt += 1;
    
    //remove from current cache slot
    [self removeObjectForKeyImpl:signature
                           error:error];
    //move to front
    [self addToFrontImpl:newNode];
    
    return node.cacheRecord;
}

- (void)addToFront:(MSIDLRUCacheNode *)node
{
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        [self addToFrontImpl:node];
    });
}

- (void)addToFrontImpl:(MSIDLRUCacheNode *)node
{
    MSIDLRUCacheNode *dummyHeadNode = [self.container objectForKey:HEAD_SIGNATURE];

    NSString *currentHeadSignature = dummyHeadNode.nextSignature; //node currently pointed by the head
    MSIDLRUCacheNode *currentHeadNode = [self.container objectForKey:currentHeadSignature];
    
    
    MSIDLRUCacheNode *updatedDummyHeadNode = [[MSIDLRUCacheNode alloc] initWithSignature:dummyHeadNode.signature
                                                                           prevSignature:dummyHeadNode.prevSignature
                                                                           nextSignature:node.signature
                                                                             cacheRecord:dummyHeadNode.cacheRecord];
    
    MSIDLRUCacheNode *updatedCurrentHeadNode = [[MSIDLRUCacheNode alloc] initWithSignature:currentHeadNode.signature
                                                                             prevSignature:node.signature
                                                                             nextSignature:currentHeadNode.nextSignature
                                                                               cacheRecord:currentHeadNode.cacheRecord];
    
    /**
    BEFORE:
     A->B->C
     A<-B<-C
    AFTER:
     A->C
     A<-C
     */
    node.prevSignature = [HEAD_SIGNATURE mutableCopy];
    node.nextSignature = [updatedCurrentHeadNode.signature mutableCopy];
    
    [self.container setObject:updatedCurrentHeadNode forKey:updatedCurrentHeadNode.signature];
    [self.container setObject:node forKey:node.signature];
    [self.container setObject:updatedDummyHeadNode forKey:HEAD_SIGNATURE];
}

- (NSArray *)enumerateAndReturnAllObjects
{
    __block NSMutableArray *res;
    dispatch_sync(self.synchronizationQueue, ^{
        res = [self enumerateAndReturnAllObjectsImpl];
    });
    return res;
}

- (NSMutableArray *)enumerateAndReturnAllObjectsImpl
{
    NSMutableArray *res;
    MSIDLRUCacheNode *dummyHeadNode = [self.container objectForKey:HEAD_SIGNATURE];
    if (![dummyHeadNode.nextSignature isEqualToString:TAIL_SIGNATURE])
    {
        res = [NSMutableArray new];
        NSMutableString *signature = [dummyHeadNode.nextSignature mutableCopy];
        
        while (![signature isEqualToString:TAIL_SIGNATURE])
        {
            MSIDLRUCacheNode *node = [self.container objectForKey:signature];
            [signature setString:node.nextSignature];
            [res addObject:node.cacheRecord];
        }
    }
    return res;
}

/**
 NOTE: no need to put these internal APIs in GCD block directly,
 as they are always used by calling APIs that will invoke these APIs within GCD block.
 */
- (NSString *)generateRandomSignature //mock pointer 62^8 ~ 2*10^14 randomness
{
    NSString *validLetters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:DEFAULT_SIGNATURE_LENGTH];

    for (int i=0; i< DEFAULT_SIGNATURE_LENGTH; i++)
    {
        [randomString appendFormat:@"%C", [validLetters characterAtIndex:arc4random_uniform((int)[validLetters length])]];
    }
    return randomString;
}

- (NSString *)mapKeyToSignature:(id)key
{
    NSString *signature = [self generateRandomSignature];
    [self.keySignatureMap setObject:signature forKey:key];
    return signature;
}

- (BOOL)removeAllObjects:(NSError **)error
{
    __block NSError *subError = nil;
    BOOL result = YES;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSArray *objects = [self.keySignatureMap allKeys];
        if (!objects || !objects.count)
        {
            subError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"MSIDLRUCache Error: Attempting to remove objects from an empty cache!", nil, nil, nil, nil, nil, NO);
            
        }
        for (id key in objects)
        {
            NSString *signature = [self.keySignatureMap objectForKey:key];
            [self.keySignatureMap removeObjectForKey:key];
            [self removeObjectForKeyImpl:signature error:&subError];
        }
        self.cacheUpdateCountInt = 0;
        self.cacheEvictionCountInt = 0;
        self.cacheAddCountInt = 0;
        self.cacheRemoveCountInt = 0;
        
    });
    
    if (subError)
    {
        result = NO;
    }
    
    if (error)
    {
        *error = subError;
    }
    return result;
}

@end
