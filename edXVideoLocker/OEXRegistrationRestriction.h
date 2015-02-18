//
//  OEXRegistrationRestriction.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationRestriction : NSObject

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

-(NSInteger)maxLentgh;
-(NSInteger)minLength;

@end
