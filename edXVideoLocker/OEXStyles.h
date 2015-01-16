//
//  OEXStyles.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXStyles : NSObject

+ (NSString*)styleHTMLContent:(NSString*)htmlString;

+ (UIColor*)separatorColor;

@end
