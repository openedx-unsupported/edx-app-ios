//
//  OEXParseConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXParseConfig : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;

@property (assign, nonatomic) BOOL notificationsEnabled;
@property (copy, nonatomic, nullable) NSString* applicationID;
@property (copy, nonatomic, nullable) NSString* clientKey;

@end

@interface OEXConfig (Parse)

@property (readonly, strong, nonatomic, nullable) OEXParseConfig* parseConfig;

@end

NS_ASSUME_NONNULL_END

