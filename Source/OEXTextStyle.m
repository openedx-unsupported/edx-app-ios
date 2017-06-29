//
//  OEXTextStyle.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXTextStyle.h"
#import "OEXStyles.h"
#import "UIColor+OEXHex.h"
#import "edX-Swift.h"

@interface OEXMutableTextStyle ()

- (void)applyPropertiesFromStyle:(OEXTextStyle*)style;

@end

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

- (id)init {
    NSAssert(NO, @"Please call the designated initializer: initWithWeight:size:color:");
    return [self initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:nil];
}

- (BOOL)isEqual:(id)object {
    OEXTextStyle* style = OEXSafeCastAsClass(object, OEXTextStyle);
    return style != nil
    && [style.color isEqual:self.color]
    && style.size == self.size
    && style.weight == self.weight
    && style.paragraphSpacingBefore == self.paragraphSpacingBefore
    && style.paragraphSpacing == self.paragraphSpacing
    && style.letterSpacing == self.letterSpacing
    && style.alignment == self.alignment
    && style.lineBreakMode == self.lineBreakMode;
    
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

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    OEXMutableTextStyle* copy = [[OEXMutableTextStyle allocWithZone:zone] initWithWeight:self.weight size:self.size color:self.color];
    [copy applyPropertiesFromStyle:self];
    return copy;
}

+ (CGFloat)pointSizeForTextSize:(OEXTextSize)size {
    switch (size) {
        case OEXTextSizeBase: return 14;
        case OEXTextSizeXXXXLarge: return 28;
        case OEXTextSizeXXXLarge: return 24;
        case OEXTextSizeXXLarge: return 21;
        case OEXTextSizeXLarge: return 18;
        case OEXTextSizeLarge: return 16;
        case OEXTextSizeXXXSmall: return 9;
        case OEXTextSizeXXSmall: return 10;
        case OEXTextSizeXSmall: return 11;
        case OEXTextSizeSmall: return 12;
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

- (NSAttributedString*)markdownStringWithText:(NSString*)text{
    UIFont *font = [self.attributes valueForKey:NSFontAttributeName];
    UIColor *textColor = [self.attributes valueForKey:NSForegroundColorAttributeName];
    
    NSString *formattedString = [text stringByAppendingString:[NSString stringWithFormat:@"<style>body{font-family: '%@'; font-size:%fpx; color: %@;}</style>",
                                                               font.fontName,
                                                               font.pointSize,
                                                               [textColor hexString]]];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithData:[formattedString dataUsingEncoding:NSUnicodeStringEncoding]
                                                                          options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                               documentAttributes:nil
                                                                            error:nil];
    [attributedText.mutableString replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, attributedText.mutableString.length)];
    return attributedText;
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

- (instancetype)initWithTextStyle:(OEXTextStyle*)style {
    self = [super initWithWeight:style.weight size:style.size color:style.color];
    if(self != nil) {
        [self applyPropertiesFromStyle:style];
    }
    return self;
}

- (void)applyPropertiesFromStyle:(OEXTextStyle*)style {
    self.alignment = style.alignment;
    self.letterSpacing = style.letterSpacing;
    self.lineBreakMode = style.lineBreakMode;
    self.paragraphSpacing = style.paragraphSpacing;
    self.paragraphSpacingBefore = style.paragraphSpacingBefore;
}

@end
