//
//  OEXRegistrationAgreement.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationAgreement : NSObject

@property(readonly, nonatomic, copy) NSString* url;
@property(readonly, nonatomic, copy) NSString* text;

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end
