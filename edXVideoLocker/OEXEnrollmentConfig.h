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

@property (nonatomic) BOOL enabled;
@property (strong, nonatomic, readonly) NSString *searchURL;
@property (strong, nonatomic, readonly) NSString *courseInfoURLTemplate;


@end
