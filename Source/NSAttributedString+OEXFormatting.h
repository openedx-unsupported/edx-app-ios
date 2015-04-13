//
//  NSAttributedString+OEXFormatting.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (OEXFormatting)

- (NSAttributedString*)oex_formatWithParameters:(NSDictionary*)parameters;

@end
