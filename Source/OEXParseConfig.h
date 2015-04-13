//
//  OEXParseConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXParseConfig : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;

@property (assign, nonatomic) BOOL enabled;
@property (copy, nonatomic) NSString* applicationID;
@property (copy, nonatomic) NSString* clientKey;

@end
