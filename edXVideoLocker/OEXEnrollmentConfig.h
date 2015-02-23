//
//  OEXEnrollmentConfig.h
//  edXVideoLocker
//
//  Created by Abhradeep on 11/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXEnrollmentConfig : NSObject

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic,assign,readonly) BOOL enabled;
@property (copy, nonatomic, readonly) NSString *searchURL;
@property (copy, nonatomic, readonly) NSString *courseInfoURLTemplate;
@property (copy,nonatomic,readonly)   NSString *externalSearchURL;

@end
