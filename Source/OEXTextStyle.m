//
//  OEXTextStyle.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXTextStyle.h"

#import "NSMutableDictionary+OEXSafeAccess.h"
#import "OEXStyles.h"

@interface OEXTextStyle ()

@property (assign, nonatomic) NSTextAlignment alignment;
@property (strong, nonatomic) UIColor* color;
@property (assign, nonatomic) OEXTextFont font;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) CGFloat size;

@end

@implementation OEXTextStyle

- (id)initWithFont:(OEXTextFont)font size:(CGFloat)size {
    self = [super init];
    if(self != nil) {
        self.font = font;
        self.size = size;
        self.lineBreakMode = NSLineBreakByTruncatingTail;
        self.alignment = NSTextAlignmentNatural;
    }
    return self;
}

+ (instancetype)styleWithThemeSansAtSize:(CGFloat)size {
    return [[self alloc] initWithFont:OEXTextFontThemeSans size:size];
}

- (OEXTextStyle*)asBold {
    OEXMutableTextStyle* style = self.mutableCopy;
    switch (style.font) {
        case OEXTextFontSystem:
        case OEXTextFontSystemBold:
            style.font = OEXTextFontSystemBold;
            break;
        case OEXTextFontThemeSans:
        case OEXTextFontThemeSansBold:
            style.font = OEXTextFontThemeSansBold;
            break;
    }
    return style;
}

- (OEXTextStyle*(^)(CGFloat size))withSize {
    return ^(CGFloat size) {
        OEXMutableTextStyle* style = self.mutableCopy;
        style.size = size;
        return style;
    };
}

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    OEXMutableTextStyle* copy = [[OEXMutableTextStyle allocWithZone:zone] init];
    copy.color = self.color;
    copy.size = self.size;
    copy.font = self.font;
    copy.lineBreakMode = self.lineBreakMode;
    copy.paragraphSpacing = self.paragraphSpacing;
    copy.paragraphSpacingBefore = self.paragraphSpacingBefore;
    return copy;
}

- (UIFont*)fontWithSize:(CGFloat)size type:(OEXTextFont)type {
    switch (type) {
        case OEXTextFontSystem:
            return [UIFont systemFontOfSize:size];
        case OEXTextFontSystemBold:
            return [UIFont boldSystemFontOfSize:size];
        case OEXTextFontThemeSans:
            return [[OEXStyles sharedStyles] sansSerifOfSize:size] ?: [self fontWithSize:size type:OEXTextFontSystem];
        case OEXTextFontThemeSansBold:
            return [[OEXStyles sharedStyles] boldSansSerifOfSize:size] ?: [self fontWithSize:size type:OEXTextFontSystemBold];
    }
}

- (NSDictionary*)attributes {
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = self.lineBreakMode;
    style.paragraphSpacing = self.paragraphSpacing;
    style.paragraphSpacingBefore = self.paragraphSpacingBefore;
    style.alignment = self.alignment;
    
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    [attributes setObjectOrNil:[self fontWithSize:self.size type:self.font] forKey:NSFontAttributeName];
    [attributes setObjectOrNil:self.color forKey:NSForegroundColorAttributeName];
    [attributes setObject:style forKey:NSParagraphStyleAttributeName];
    return attributes;
}

- (NSAttributedString*)attributedStringWithText:(NSString *)text {
    return [[NSAttributedString alloc] initWithString:text ?: @"" attributes:self.attributes];
}

- (void)applyToLabel:(UILabel *)label {
    UIFont* font = [self fontWithSize:self.size type:self.font];
    label.font = font;
    label.textColor = self.color;
    label.textAlignment = self.alignment;
}

@end

@implementation OEXMutableTextStyle

@dynamic alignment;
@dynamic color;
@dynamic font;
@dynamic lineBreakMode;
@dynamic paragraphSpacing;
@dynamic paragraphSpacingBefore;
@dynamic size;

+ (instancetype)style {
    return [[self alloc] initWithFont:OEXTextFontThemeSans size:12];
}

@end