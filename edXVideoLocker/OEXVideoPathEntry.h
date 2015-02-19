//
//  OEXVideoPathEntry.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OEXVideoPathEntryCategory) {
    OEXVideoPathEntryCategoryUnknown,
    OEXVideoPathEntryCategoryChapter,
    OEXVideoPathEntryCategorySection
};

@interface OEXVideoPathEntry : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (id)initWithEntryID:(NSString*)entryID name:(NSString*)name category:(NSString*)category;

@property (readonly, assign, nonatomic) OEXVideoPathEntryCategory category;
@property (readonly, copy, nonatomic) NSString* entryID;
@property (readonly, copy, nonatomic) NSString* name;

@end
