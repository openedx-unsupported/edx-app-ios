//
//  OEXParseConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXParseConfig : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;

@property (assign, nonatomic) BOOL notificationsEnabled;
@property (copy, nonatomic) NSString* applicationID;
@property (copy, nonatomic) NSString* clientKey;

@end

NS_ASSUME_NONNULL_END

