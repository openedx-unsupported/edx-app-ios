//
//  NSAttributedString+OEXFormatting.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (OEXFormatting)

/// @param parameters A map between keys and NSAttributedStrings to replace those strings with.
/// See -[NSString oex_formatWithParameters:] for a more detailed description.
- (NSAttributedString*)oex_formatWithParameters:(NSDictionary<NSString*, NSAttributedString*>*)parameters;

@end

NS_ASSUME_NONNULL_END
