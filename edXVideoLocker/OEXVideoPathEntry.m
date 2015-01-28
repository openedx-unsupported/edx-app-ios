//
//  OEXVideoPathEntry.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXVideoPathEntry.h"


@interface OEXVideoPathEntry ()

@property (copy, nonatomic) NSString* category;
@property (copy, nonatomic) NSString* entryID;
@property (copy, nonatomic) NSString* name;

@end

@implementation OEXVideoPathEntry

- (id)initWithDictionary:(NSDictionary *)dictionary {
    NSString* entryID = dictionary[@"id"];
    NSString* name = dictionary[@"name"];
    NSString* category = dictionary[@"category"];
    
    self = [self initWithEntryID:entryID name:name category:category];
    return self;
}

- (id)initWithEntryID:(NSString*)entryID name:(NSString*)name category:(NSString*)category {
    self = [super init];
    if(self != nil) {
        self.entryID = entryID;
        self.name = name;
        self.category = category;
    }
    return self;
}

- (NSUInteger)hash {
    return self.entryID.hash;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[OEXVideoPathEntry class]] && [self.entryID isEqual:[object entryID]];
}

@end