//
//  OEXLatestUpdates.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXLatestUpdates : NSObject

- (id)initWithDictionary:(NSDictionary*)info;

@property (nonatomic, strong, nullable) NSString* video;

@end

NS_ASSUME_NONNULL_END
