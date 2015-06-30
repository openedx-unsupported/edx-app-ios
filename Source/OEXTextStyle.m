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
@property (assign, nonatomic) OEXLetterSpacing letterSpacing;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) OEXTextSize size;
@property (assign, nonatomic) OEXTextWeight weight;

@end

@implementation OEXTextStyle

- (id)initWithWeight:(OEXTextWeight)weight size:(OEXTextSize)size color:(UIColor*)color {
    self = [super init];
    if(self != nil) {
        self.color = color;
        self.weight = weight;
        self.size = size;
        self.letterSpacing = OEXLetterSpacingNormal;
        self.lineBreakMode = NSLineBreakByTruncatingTail;
        self.alignment = NSTextAlignmentNatural;
    }
    return self;
}

- (OEXTextStyle*(^)(OEXTextWeight weight))withWeight {
    return ^(OEXTextWeight weight) {
        OEXMutableTextStyle* style = self.mutableCopy;
        style.weight = weight;
        return style;
    };
}

- (OEXTextStyle*(^)(OEXTextSize size))withSize {
    return ^(OEXTextSize size) {
        OEXMutableTextStyle* style = self.mutableCopy;
        style.size = size;
        return style;
    };
}

- (OEXTextStyle*(^)(UIColor* color))withColor {
    return ^(UIColor* color) {
        OEXMutableTextStyle* style = self.mutableCopy;
        style.color = color;
        return style;
    };
}

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    OEXMutableTextStyle* copy = [[OEXMutableTextStyle allocWithZone:zone] init];
    copy.color = self.color;
    copy.letterSpacing = self.letterSpacing;
    copy.lineBreakMode = self.lineBreakMode;
    copy.paragraphSpacing = self.paragraphSpacing;
    copy.paragraphSpacingBefore = self.paragraphSpacingBefore;
    copy.size = self.size;
    copy.weight = self.weight;
    return copy;
}

+ (CGFloat)pointSizeForTextSize:(OEXTextSize)size {
    switch (size) {
        case OEXTextSizeBase: return 16;
        case OEXTextSizeXXXXLarge: return 38;
        case OEXTextSizeXXXLarge: return 28;
        case OEXTextSizeXXLarge: return 24;
        case OEXTextSizeXLarge: return 21;
        case OEXTextSizeLarge: return 18;
        case OEXTextSizeXXXSmall: return 10;
        case OEXTextSizeXXSmall: return 11;
        case OEXTextSizeXSmall: return 12;
        case OEXTextSizeSmall: return 14;
    }
}

- (UIFont*)fontWithWeight:(OEXTextWeight)weight size:(OEXTextSize)size {
    CGFloat pointSize = [[self class] pointSizeForTextSize:size];
    switch (weight) {
        case OEXTextWeightNormal:
            return [[OEXStyles sharedStyles] sansSerifOfSize:pointSize] ?: [UIFont systemFontOfSize:pointSize];
        case OEXTextWeightLight:
            return [[OEXStyles sharedStyles] lightSansSerifOfSize:pointSize] ?: [UIFont systemFontOfSize:pointSize];
        case OEXTextWeightSemiBold:
            return [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:pointSize] ?: [UIFont boldSystemFontOfSize:pointSize];
        case OEXTextWeightBold:
            return [[OEXStyles sharedStyles] boldSansSerifOfSize:pointSize] ?: [UIFont boldSystemFontOfSize:pointSize];
    }
}

- (NSNumber*)kerningForLetterSpacing:(OEXLetterSpacing)spacing {
    switch (spacing) {
        case OEXLetterSpacingNormal: return nil;
        case OEXLetterSpacingLoose: return @(0.95);
        case OEXLetterSpacingXLoose: return @(2);
        case OEXLetterSpacingXXLoose: return @(3);
        case OEXLetterSpacingTight: return @(-.95);
        case OEXLetterSpacingXTight: return @(-2);
        case OEXLetterSpacingXXTight: return @(-3);
    }
}

- (NSDictionary*)attributes {
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = self.lineBreakMode;
    style.paragraphSpacing = self.paragraphSpacing;
    style.paragraphSpacingBefore = self.paragraphSpacingBefore;
    style.alignment = self.alignment;
    
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    [attributes setObjectOrNil:[self fontWithWeight:self.weight size:self.size] forKey:NSFontAttributeName];
    [attributes setObjectOrNil:self.color forKey:NSForegroundColorAttributeName];
    [attributes setObject:style forKey:NSParagraphStyleAttributeName];
    
    if (self.letterSpacing != OEXLetterSpacingNormal) {
        [attributes setObjectOrNil:[self kerningForLetterSpacing:self.letterSpacing] forKey:NSKernAttributeName];
    }
    
    return attributes;
}

- (NSAttributedString*)attributedStringWithText:(NSString *)text {
    return [[NSAttributedString alloc] initWithString:text ?: @"" attributes:self.attributes];
}

@end

@implementation OEXMutableTextStyle

@dynamic alignment;
@dynamic color;
@dynamic letterSpacing;
@dynamic lineBreakMode;
@dynamic paragraphSpacing;
@dynamic paragraphSpacingBefore;
@dynamic size;
@dynamic weight;

+ (instancetype)style {
    return [[self alloc] initWithWeight:OEXTextWeightNormal size:12 color:nil];
}

@end