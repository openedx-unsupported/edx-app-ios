//
//  EDXAnnouncement.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDXAnnouncement : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (copy, nonatomic) NSString* heading;
@property (copy, nonatomic) NSString* content; //HTML text

@end
