//
//  OEXAnnouncement.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/4/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXAnnouncement : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (copy, nonatomic, nullable) NSString* heading;
@property (copy, nonatomic, nullable) NSString* content;  //HTML text

@end

NS_ASSUME_NONNULL_END
