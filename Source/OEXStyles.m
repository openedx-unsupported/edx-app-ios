//
//  OEXStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStyles.h"

static OEXStyles* sSharedStyles;

@implementation OEXStyles

+ (instancetype)sharedStyles {
    return sSharedStyles;
}

+ (void)setSharedStyles:(OEXStyles*)styles {
    sSharedStyles = styles;
}

- (UIFont*)sansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans" size:size];
}

- (UIFont*)boldSansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:size];
}

- (NSString*)styleHTMLContent:(NSString*)htmlString {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"handouts-announcements" ofType:@"css"];
    NSError* error = nil;
    NSMutableString* css = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSAssert(!error, @"Error loading style: %@", error.localizedDescription);

    NSMutableString* styledHTML = htmlString.mutableCopy;
    [styledHTML appendString:@"</html>"];
    [styledHTML appendString:@"</body>"];
    [styledHTML insertString:@"</style>" atIndex:0];
    [styledHTML insertString:css atIndex:0];
    [styledHTML insertString:@"<style>" atIndex:0];

    [styledHTML insertString:@"<body>" atIndex:0];
    [styledHTML insertString:@"</head>" atIndex:0];
    [styledHTML insertString:@"<meta name = \"viewport\" content = \"width=device-width, initial-scale=1\"/>" atIndex:0];
    [styledHTML insertString:@"<head>" atIndex:0];
    [styledHTML insertString:@"<html>" atIndex:0];
    return styledHTML;
}

@end
