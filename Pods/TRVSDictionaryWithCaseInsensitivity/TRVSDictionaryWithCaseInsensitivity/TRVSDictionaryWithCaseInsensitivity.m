//
//  TRVSDictionaryWithCaseInsensitivity.m
//  TRVSDictionaryWithCaseInsensitivity
//
//  Created by Travis Jeffery on 7/24/14.
//  Copyright (c) 2014 Travis Jeffery. All rights reserved.
//

#import "TRVSDictionaryWithCaseInsensitivity.h"

@implementation TRVSDictionaryWithCaseInsensitivity {
  NSDictionary *_dict;
}

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
  if (self = [super init]) {
    _dict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:cnt];
  }
  return self;
}

- (NSUInteger)count {
  return _dict.count;
}

- (NSEnumerator *)keyEnumerator {
  return _dict.keyEnumerator;
}

- (id)objectForKey:(id)aKey {
  __block id result = nil;
  [self objectAndKeyForKey:aKey block:^(id obj, id key) {
    result = obj;
  }];
  return result;
}

- (void)objectAndKeyForKey:(id)key block:(void (^)(id obj, id key))block {
  id obj = [_dict objectForKey:key];
  
  if (obj != nil || ![key isKindOfClass:[NSString class]]) {
    block(obj, key);
    return;
  }
  
  for (id aKey in _dict.keyEnumerator) {
    if ([aKey isKindOfClass:[NSString class]] && [aKey caseInsensitiveCompare:key] == NSOrderedSame) {
      block([_dict objectForKey:aKey], aKey);
      return;
    }
  }
}

@end
