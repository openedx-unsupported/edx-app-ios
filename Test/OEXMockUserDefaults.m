//
//  OEXMockUserDefaults.m
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMockUserDefaults.h"

#import <OCMock/OCMock.h>
#import "OEXRemovable.h"

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

- (BOOL)boolForKey:(NSString *)key {
    return [self.store[key] boolValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    self.store[key] = @(value);
}

- (NSInteger)integerForKey:(NSString*)key {
    return [self.store[key] integerValue];
}

- (void)setInteger:(NSInteger)value forKey:(NSString*)key {
    self.store[key] = @(value);
}

- (void)removeObjectForKey:(NSString*)key {
    [self.store removeObjectForKey:key];
}

- (void)synchronize {
    // We don't write to disk so do nothing
}

- (id <OEXRemovable>)installAsStandardUserDefaults {
    OCMockObject* defaultsClassMock = OCMStrictClassMock([NSUserDefaults class]);
    id defaultsStub = [defaultsClassMock stub];
    [defaultsStub standardUserDefaults];
    [defaultsStub andReturn:self];
    return [[OEXBlockRemovable alloc] initWithRemovalAction:^{
        [defaultsClassMock stopMocking];
    }];
}

@end
