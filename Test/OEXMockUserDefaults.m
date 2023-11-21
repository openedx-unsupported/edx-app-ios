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
@property (strong, nonatomic) NSDictionary* defaults;

@end

@implementation OEXMockUserDefaults

- (id)init {
    self = [super init];
    if(self != nil) {
        self.store = [[NSMutableDictionary alloc] init];
        self.defaults = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    return self.store[key] ?: self.defaults[key];
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

- (NSString*)stringForKey:(NSString*)key {
    id value = self.store[key];
    if([value isKindOfClass:[NSString class]]) {
        return value;
    }
    else {
        return [value stringValue];
    }
}

- (void)setString:(NSString*)string forKey:(NSString*)key {
    [self setObject:string forKey:key];
}

- (NSURL*)URLForKey:(NSString*)key {
    return [NSURL URLWithString:[self stringForKey:key]];
}

- (void)setURL:(NSURL*)URL forKey:(NSString*)key {
    [self setObject:URL.absoluteString forKey:key];
}

- (NSInteger)integerForKey:(NSString*)key {
    return [self.store[key] integerValue];
}

- (void)setInteger:(NSInteger)value forKey:(NSString*)key {
    self.store[key] = @(value);
}

- (double) doubleForKey:(NSString *)key {
    return [self.store[key] doubleValue];
}

-(void) setDouble:(double)value forKey:(NSString *)key {
    self.store[key] = @(value);
}

- (void)removeObjectForKey:(NSString*)key {
    [self.store removeObjectForKey:key];
}

- (void)registerDefaults:(NSDictionary*)defaults {
    self.defaults = defaults;
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
