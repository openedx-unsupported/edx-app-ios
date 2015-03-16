//
//  OEXFabricConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXFabricConfig : NSObject
@property(nonatomic, copy) NSString* appKey;
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
-(instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end
