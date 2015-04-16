//
//  OEXMockUserDefaults.m
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMockUserDefaults.h"

@interface OEXMockUserDefaults ()

@property (strong, nonatomic) NSMutableDictionary* store;

@end

@implementation OEXMockUserDefaults

- (id)init {
    self = [super init];
    if(self != nil) {
        self.store = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    return self.store[key];
}

- (void)setObject:(id)object forKey:(NSString*)key {
    [self.store setObject:object forKey:key];
}

- (void)synchronize {
    // We don't write to disk so do nothing
}

@end
