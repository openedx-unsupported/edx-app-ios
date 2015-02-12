//
//  OEXEnrollmentConfig.h
//  edXVideoLocker
//
//  Created by Abhradeep on 11/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXEnrollmentConfig : NSObject

+ (instancetype)sharedEnrollmentConfig;

-(BOOL)enabled;

-(NSString *)searchURL;

-(NSString *)courseInfoURLTemplate;

@end
