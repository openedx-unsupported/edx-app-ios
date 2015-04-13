//
//  OEXZeroRatingConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXZeroRatingConfig : NSObject
@property(nonatomic, assign, getter = isEnabled) BOOL enabled;
//array:NSString
- (NSArray*)carriers;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end
