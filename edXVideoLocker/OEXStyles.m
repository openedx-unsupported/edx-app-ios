//
//  OEXStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStyles.h"

@implementation OEXStyles

+ (NSString*)styleHTMLContent:(NSString*)htmlString {
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

+ (UIFont*)sansSerifWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans" size:size];
}

+ (UIColor*)separatorColor {
    return [UIColor colorWithWhite:.71 alpha:1];
}

@end


@implementation OEXStyles (EDXAnnouncements)

+ (UIFont*)announcementHeaderFont {
    return [self sansSerifWithSize:14];
}

+ (UIColor*)announcementHeaderColor {
    return [UIColor colorWithRed:70./255. green:74./255. blue:80./255. alpha:1.0];
}

+ (CGFloat)announcementsSectionSpacing {
    return 10;
}

+ (CGFloat)announcementHorizontalMargin {
    return 20;
}

+ (CGFloat)announcementTitleVerticalMargin {
    return 10;
}

@end