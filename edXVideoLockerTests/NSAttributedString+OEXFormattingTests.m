//
//  NSAttributedString+OEXFormattingTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSAttributedString+OEXFormatting.h"

@interface NSAttributedString_OEXFormatting : XCTestCase

@end

@implementation NSAttributedString_OEXFormatting

- (void)testFormatNoParams {
    NSAttributedString* format = [[NSAttributedString alloc] initWithString:@"some string with { stuff in it" attributes:nil];
    NSAttributedString* result = [format oex_formatWithParameters:@{}];
    XCTAssertEqualObjects(result.string, format.string);
}

- (void)testFormatReplacement {
    CGFloat baseSize = 14;
    CGFloat otherSize = 18;
    
    NSAttributedString* format = [[NSAttributedString alloc] initWithString:@"{param} string with {param} stuff in it" attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:baseSize] }];
    NSAttributedString* replacement = [[NSAttributedString alloc] initWithString:@"some" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:otherSize]}];
    NSAttributedString* result = [format oex_formatWithParameters:@{@"param" : replacement}];
    XCTAssertEqualObjects(result.string, @"some string with some stuff in it");
    
    NSRange range;
    UIFont* font = [result attribute:NSFontAttributeName atIndex:0 effectiveRange:&range];
    XCTAssertEqual(range.location, 0);
    XCTAssertEqual(range.length, 4);
    XCTAssertEqual(font.pointSize, otherSize);
    
    font = [result attribute:NSFontAttributeName atIndex:5 effectiveRange:nil];
    XCTAssertEqual(font.pointSize, baseSize);
    
    font = [result attribute:NSFontAttributeName atIndex:18 effectiveRange:&range];
    XCTAssertEqual(font.pointSize, otherSize);
    XCTAssertEqual(range.location, 17);
    XCTAssertEqual(range.length, 4);
}

@end
