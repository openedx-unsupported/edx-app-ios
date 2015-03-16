//
//  OEXRegistrationOption.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationOption : NSObject

@property(readonly, nonatomic, copy) NSString* name;
@property(readonly, nonatomic, copy) NSString* value;
@property(readonly, nonatomic, assign) BOOL isDefault;
-(instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end
